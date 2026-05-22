import Foundation

public typealias BridgeDefaultCodexFactory = (_ config: BridgeConfig, _ interactiveCallbackResponder: CodexInteractiveCallbackResponder?) -> any CodexBackend

public final class BridgeService: @unchecked Sendable {
    private let paths: RuntimePaths
    private let stores: RuntimeStores
    private let makeSource: (BridgeConfig) -> MessageSource
    private let makeReplySink: (BridgeConfig) -> ReplySink
    private let makeCodex: (BridgeConfig) -> any CodexBackend
    private let makeDefaultCodex: BridgeDefaultCodexFactory
    private let useDefaultCodexBackend: Bool
    private let now: () -> Date
    private let stateBox: BridgeStateBox
    private var stopped = false
    private let jobQueue = BridgeJobQueue()
    private var activeCodexTask: Task<Void, Never>?
    private var state: BridgeState {
        get { stateBox.snapshot() }
        set { stateBox.replace(newValue) }
    }

    public init(
        paths: RuntimePaths = .current(),
        stores: RuntimeStores? = nil,
        makeSource: @escaping (BridgeConfig) -> MessageSource,
        makeReplySink: @escaping (BridgeConfig) -> ReplySink,
        makeCodex: @escaping (BridgeConfig) -> any CodexBackend,
        makeDefaultCodex: BridgeDefaultCodexFactory? = nil,
        useDefaultCodexBackend: Bool = false,
        now: @escaping () -> Date = Date.init
    ) {
        self.paths = paths
        self.stores = stores ?? RuntimeStores(paths: paths)
        self.makeSource = makeSource
        self.makeReplySink = makeReplySink
        self.makeCodex = makeCodex
        self.makeDefaultCodex = makeDefaultCodex ?? { config, responder in
            CodexAppServerBackend(config: config, paths: paths, interactiveCallbackResponder: responder)
        }
        self.useDefaultCodexBackend = useDefaultCodexBackend
        self.now = now
        self.stateBox = BridgeStateBox(defaultBridgeState())
    }

    public convenience init(paths: RuntimePaths = .current()) {
        self.init(
            paths: paths,
            makeSource: { SQLiteMessageSource(dbPath: $0.messagesDbPath, trustedSenders: $0.effectiveTrustedSenders) },
            makeReplySink: { AppleMessagesReplySink(osascriptCommand: $0.osascriptCommand, chunkSize: $0.chunkSize, messagesDbPath: $0.messagesDbPath) },
            makeCodex: { CodexAppServerBackend(config: $0, paths: paths) },
            useDefaultCodexBackend: true
        )
    }

    public func initialize() async throws {
        try ensureRuntimeDirectories(paths)
        var config = try stores.config.ensureExists()
        migrateTrustedSenders(&config)
        try stores.config.save(config)
        state = try stores.state.load()
        recoverActiveJobOnStartup()
        try validateConfig(config)
        backfillExistingAutomationRoutes(config: config)
        var cursorState = state
        try await makeSource(config).initializeCursor(state: &cursorState)
        state = cursorState
        try stores.state.save(state)
    }

    public func runForever() async throws {
        try await initialize()
        while !stopped {
            try await tick()
            let config = try stores.config.load()
            try await Task.sleep(nanoseconds: UInt64(config.pollIntervalMs) * 1_000_000)
        }
    }

    public func stop() {
        stopped = true
    }

    public func tick() async throws {
        let config = try stores.config.load()
        try await expirePendingInteractiveCallbackIfNeeded(config: config)
        try await recoverDetachedActiveJobIfNeeded(config: config)
        try await deliverCompletedAutomationRuns(config: config)
        let messages = try await makeSource(config).fetchNewMessages(afterRowId: state.lastProcessedRowId)
        for message in messages {
            if shouldDeferForMissingAttachments(message, now: now()) {
                break
            }
            try mutateStateAndSave { state in
                state.lastProcessedGuid = message.guid
                state.lastProcessedRowId = message.rowId
            }
            recordInboundMediaRefs(message)
            processIncoming(config: config, message: message)
        }
        try await syncPendingBatch(config: config)
        try await drainQueue()
        try saveStateSnapshot()
    }

    private func processIncoming(config: BridgeConfig, message: MessageItem) {
        if shouldRouteToPendingInteractiveCallback(message) {
            jobQueue.enqueueInteractiveCallbackReply(message)
            return
        }
        if state.activeJob != nil {
            if let command = localCommandName(message.text), message.attachments.isEmpty {
                jobQueue.enqueueLocalCommand(command, message)
            } else {
                appendToPendingBatch(config: config, message: message)
            }
            return
        }
        if let command = localCommandName(message.text), message.attachments.isEmpty {
            finalizePendingBatch()
            jobQueue.enqueueLocalCommand(command, message)
            return
        }
        appendToPendingBatch(config: config, message: message)
    }

    private func shouldDeferForMissingAttachments(_ message: MessageItem, now: Date) -> Bool {
        shouldDeferMessageForMissingAttachments(message, now: now)
    }

    private func appendToPendingBatch(config: BridgeConfig, message: MessageItem) {
        let messageDate = DateCodec.parse(message.receivedAt) ?? now()
        let finalized = stateBox.mutate { state in
            state.appendPendingBatchMessage(message, batchWindowMs: config.batchWindowMs, messageDate: messageDate)
        }
        if let finalized {
            jobQueue.enqueuePromptBatch(finalized)
        }
    }

    @discardableResult
    private func finalizePendingBatch() -> PendingBatch? {
        let batch = stateBox.mutate { state in
            state.finalizePendingBatchForQueue()
        }
        if let batch {
            jobQueue.enqueuePromptBatch(batch)
        }
        return batch
    }

    private func syncPendingBatch(config: BridgeConfig) async throws {
        guard let pending = state.pendingBatch else { return }
        guard let deadline = DateCodec.parse(pending.deadlineAt), deadline > now() else {
            finalizePendingBatch()
            return
        }
    }

    private func drainQueue() async throws {
        while let job = jobQueue.dequeueNext(hasActiveJob: state.activeJob != nil) {
            switch job {
            case .localCommand(let command, let message):
                try await handleLocalCommand(command, message: message)
            case .interactiveCallbackReply(let message):
                try await handleInteractiveCallbackReply(message)
            case .promptBatch(let batch):
                if state.activeJob == nil {
                    try await startPromptBatch(batch)
                }
            }
        }
    }

    private func shouldRouteToPendingInteractiveCallback(_ message: MessageItem) -> Bool {
        guard let callback = state.pendingInteractiveCallback,
              callback.status == "pending",
              callback.recipient == message.handleId,
              callback.service == message.service else {
            return false
        }
        if message.attachments.isEmpty, localCommandName(message.text) != nil {
            return false
        }
        return true
    }

    private func handleInteractiveCallbackReply(_ message: MessageItem) async throws {
        guard let callback = stateBox.mutate({ state in
            state.markPendingInteractiveCallbackAnswered(message: message, answeredAt: DateCodec.iso(now()))
        }) else { return }
        if let jobId = callback.jobId {
            updateActiveJob(jobId: jobId) { job in
                job.status = "waitingForUser"
                job.lastObservedSummary = "Captured a Messages reply for pending app-server callback \(callback.callbackId)."
                job.lastEventAt = DateCodec.iso(now())
            }
        }
        try saveStateSnapshot()
        let config = try stores.config.load()
        if callback.method == bridgeSmokeCallbackMethod {
            try mutateStateAndSave { state in
                state.clearPendingInteractiveCallback()
            }
            let marker = callback.jsonRpcId ?? callback.callbackId
            try await sendReplyRecording(
                makeReplySink(config),
                recipient: message.handleId,
                service: message.service,
                text: """
                Smoke callback passed: \(marker)
                Reply row: \(message.rowId)
                Reply guid: \(message.guid)
                Captured: \(message.text)
                """
            )
            return
        }
        try await sendReplyRecording(
            makeReplySink(config),
            recipient: message.handleId,
            service: message.service,
            text: "Got it. I captured that reply for the pending Codex prompt."
        )
    }

    private func expirePendingInteractiveCallbackIfNeeded(config: BridgeConfig) async throws {
        guard let callback = stateBox.mutate({ state in
            state.markPendingInteractiveCallbackExpired(now: now())
        }) else {
            return
        }
        if let jobId = callback.jobId {
            updateActiveJob(jobId: jobId) { job in
                job.status = "failed"
                job.lastObservedSummary = callback.failureText
                job.lastEventAt = DateCodec.iso(now())
            }
        }
        try saveStateSnapshot()
        try await sendReplyRecording(
            makeReplySink(config),
            recipient: callback.recipient,
            service: callback.service,
            text: "The pending Codex prompt timed out waiting for your reply."
        )
        try mutateStateAndSave { state in
            state.clearPendingInteractiveCallback()
        }
    }

    private func interactiveCallbackResponder(jobId: String, replySink: ReplySink, recipient: String, service: String, config: BridgeConfig) -> CodexInteractiveCallbackResponder {
        { [weak self] method, requestId, params in
            guard let self else {
                return interactiveCallbackCancelResponse(method: method, answer: nil, params: params)
            }
            return try self.handleAppServerInteractiveCallback(
                method: method,
                requestId: requestId,
                params: params,
                jobId: jobId,
                replySink: replySink,
                recipient: recipient,
                service: service,
                config: config
            )
        }
    }

    private func handleAppServerInteractiveCallback(method: String, requestId: Any, params: [String: Any]?, jobId: String, replySink: ReplySink, recipient: String, service: String, config: BridgeConfig) throws -> [String: Any] {
        let callbackId = UUID().uuidString
        let startedAt = now()
        let waitMs = max(1_000, config.timeoutMs - 1_000)
        let deadline = startedAt.addingTimeInterval(Double(waitMs) / 1_000)
        let callback = PendingInteractiveCallback(
            callbackId: callbackId,
            jobId: jobId,
            jsonRpcId: String(describing: requestId),
            method: method,
            recipient: recipient,
            service: service,
            prompt: interactiveCallbackPrompt(method: method, params: params),
            createdAt: DateCodec.iso(startedAt),
            expiresAt: DateCodec.iso(deadline),
            status: "pending"
        )
        let stateToSave = stateBox.mutate { state in
            state.setPendingInteractiveCallback(callback)
            if var job = state.activeJob, job.jobId == jobId {
                job.status = "waitingForUser"
                job.lastObservedSummary = "Codex is waiting for a Messages reply to continue."
                job.lastEventAt = DateCodec.iso(startedAt)
                state.activeJob = job
            }
            return state
        }
        try stores.state.save(stateToSave)
        try runAsyncBlocking {
            try await self.sendReplyRecording(
                replySink,
                recipient: recipient,
                service: service,
                text: """
                Codex needs your input to continue:
                \(callback.prompt)

                Reply here with your answer, or send /cancel.
                """
            )
        }
        guard let answer = try waitForInteractiveCallbackAnswer(callbackId: callbackId, until: deadline) else {
            markInteractiveCallbackFinished(callbackId: callbackId, status: "timedOut", failureText: "Timed out waiting for a Messages reply.")
            try runAsyncBlocking {
                try await self.sendReplyRecording(replySink, recipient: recipient, service: service, text: "The pending Codex prompt timed out waiting for your reply.")
            }
            return interactiveCallbackCancelResponse(method: method, answer: nil, params: params)
        }
        markInteractiveCallbackFinished(callbackId: callbackId, status: "completed", failureText: nil)
        return interactiveCallbackSuccessResponse(method: method, answer: answer, params: params)
    }

    private func waitForInteractiveCallbackAnswer(callbackId: String, until deadline: Date) throws -> String? {
        while Date() < deadline {
            let latest = try stores.state.load().pendingInteractiveCallback
            if latest?.callbackId != callbackId {
                return nil
            }
            switch latest?.status {
            case "answered":
                return latest?.responseText ?? ""
            case "canceled", "cancelled", "timedOut", "timeout", "failed":
                return nil
            default:
                Thread.sleep(forTimeInterval: 0.25)
            }
        }
        return nil
    }

    private func markInteractiveCallbackFinished(callbackId: String, status: String, failureText: String?) {
        let snapshots = stateBox.mutate { state -> [BridgeState] in
            guard state.markPendingInteractiveCallbackFinished(callbackId: callbackId, status: status, failureText: failureText) != nil else { return [] }
            let terminalState = state
            state.clearPendingInteractiveCallback()
            return [terminalState, state]
        }
        for snapshot in snapshots {
            try? stores.state.save(snapshot)
        }
    }

    private func handleLocalCommand(_ command: String, message: MessageItem) async throws {
        let config = try stores.config.load()
        if command == "/codex", message.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "/codex retry-last-send" {
            let text = try await retryLastOutboundSend(config: config)
            _ = try await makeReplySink(config).sendReply(recipient: message.handleId, service: message.service, text: text)
            try stores.state.save(state)
            return
        }
        if command == "/codex", isCodexSmokeCommand(message.text) {
            try await runCodexSmokeCommand(message.text, message: message, config: config)
            try stores.state.save(state)
            return
        }
        let text = command == "/codex"
            ? try await runCodexCommand(message.text, config: config)
            : runLocalCommand(message.text)
        try await sendReplyRecording(makeReplySink(config), recipient: message.handleId, service: message.service, text: text)
        try stores.state.save(state)
    }

    private func saveStateSnapshot() throws {
        try stores.state.save(stateBox.snapshot())
    }

    @discardableResult
    private func mutateStateAndSave<T>(_ update: (inout BridgeState) throws -> T) throws -> T {
        var result: Result<T, Error>?
        let snapshot = stateBox.mutate { state -> BridgeState in
            do {
                result = .success(try update(&state))
            } catch {
                result = .failure(error)
            }
            return state
        }
        try stores.state.save(snapshot)
        return try result!.get()
    }

    private func runCodexCommand(_ command: String, config: BridgeConfig) async throws -> String {
        let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "/codex status":
            let snapshot = await cachedCodexCapabilitiesBestEffort(command: config.codex.command, paths: paths, ttlMs: Int.max, refreshTimeoutMs: 5_000)
            return codexStatusText(capabilitySnapshot: snapshot)
        case "/codex open":
            guard let threadId = state.codexSession.sessionId, !threadId.isEmpty else {
                return "There is no active Codex thread to open yet."
            }
            do {
                try await openCodexThread(threadId)
                return "Opened Codex thread \(threadId)."
            } catch {
                return "I found Codex thread \(threadId), but could not open it in Codex.app: \(error)"
            }
        case "/codex history":
            guard let threadId = state.codexSession.sessionId, !threadId.isEmpty else {
                return "There is no active Codex thread history yet."
            }
            do {
                return try await readCodexThreadHistory(command: config.codex.command, threadId: threadId)
            } catch let error as CodexAppServerError {
                return "I could not read Codex thread history: \(error.description)"
            } catch {
                return "I could not read Codex thread history: \(error)"
            }
        case "/codex automations":
            return codexAutomationRoutesText()
        case "/codex gates":
            return bridgeGateChecklistText(context: BridgeGateChecklistContext(
                allowedSender: config.allowedSender,
                service: "iMessage",
                hasActiveJob: state.activeJob != nil,
                hasPendingInteractiveCallback: state.pendingInteractiveCallback != nil,
                hasRecentInboundImage: hasUsableRecentMedia(direction: "inbound", recipient: config.allowedSender, service: "iMessage"),
                hasRecentOutboundImage: hasUsableRecentMedia(direction: "outbound", recipient: config.allowedSender, service: "iMessage")
            ))
        default:
            return "Use /codex status, /codex open, /codex history, /codex automations, /codex gates, /codex retry-last-send, or /codex smoke text|attachment|automation|callback|bridge-attach|generated-image|app-server-callback|app-server|inbound-image-check|outbound-image-check|chrome|browser|computer-use."
        }
    }

    private func runCodexSmokeCommand(_ command: String, message: MessageItem, config: BridgeConfig) async throws {
        let sink = makeReplySink(config)
        let subcommand = codexSmokeSubcommand(command)
        let marker = "CODEX_BRIDGE_SMOKE_\(subcommand.uppercased())_\(UUID().uuidString)"
        let summary: String
        switch subcommand {
        case "text":
            do {
                try await sendReplyRecording(sink, recipient: message.handleId, service: message.service, text: marker)
                summary = """
                Smoke text passed: \(marker)
                Evidence: \(lastOutboundSendStatusText())
                """
            } catch {
                summary = """
                Smoke text failed: \(marker)
                Error: \(error)
                Evidence: \(lastOutboundSendStatusText())
                """
            }
        case "attachment":
            do {
                try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
                let attachment = paths.tmpDir.appendingPathComponent("codex-bridge-smoke-\(marker).png")
                try bridgeSmokePNGData().write(to: attachment)
                try await sendAttachmentRecording(sink, recipient: message.handleId, service: message.service, filePath: attachment.path)
                summary = """
                Smoke attachment passed: \(marker)
                Attachment: \(attachment.path)
                Evidence: \(lastOutboundSendStatusText())
                """
            } catch {
                summary = """
                Smoke attachment failed: \(marker)
                Error: \(error)
                Evidence: \(lastOutboundSendStatusText())
                """
            }
        case "bridge-attach":
            do {
                try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
                let attachment = paths.tmpDir.appendingPathComponent("codex-bridge-smoke-\(marker).png")
                try bridgeSmokePNGData().write(to: attachment)
                try await sendOutgoingReply(
                    "\(marker) generated image ready.\nBRIDGE_ATTACH: \(attachment.path)",
                    replySink: sink,
                    recipient: message.handleId,
                    service: message.service,
                    config: config,
                    request: PromptRequest(promptText: command, attachments: [])
                )
                summary = """
                Smoke bridge-attach passed: \(marker)
                Attachment: \(attachment.path)
                Evidence: \(lastOutboundSendStatusText())
                """
            } catch {
                summary = """
                Smoke bridge-attach failed: \(marker)
                Error: \(error)
                Evidence: \(lastOutboundSendStatusText())
                """
            }
        case "generated-image":
            do {
                summary = try await startGeneratedImageSmoke(marker: marker, message: message)
            } catch {
                summary = """
                Smoke generated-image failed: \(marker)
                Error: \(error)
                Evidence: \(lastOutboundSendStatusText())
                """
            }
        case "automation":
            do {
                let result = try createCodexAutomationSmoke(
                    recipient: message.handleId,
                    service: message.service,
                    config: config,
                    paths: paths,
                    stores: stores,
                    marker: marker
                )
                state = try stores.state.load()
                summary = """
                Smoke automation passed: \(result.marker)
                Automation id: \(result.automation.id)
                Automation file: \(result.automation.path)
                Route: \(result.route.recipient) via \(result.route.service)
                """
            } catch {
                summary = """
                Smoke automation failed: \(marker)
                Error: \(error)
                """
            }
        case "callback":
            do {
                summary = try await startBridgeCallbackSmoke(marker: marker, message: message, config: config)
            } catch {
                summary = """
                Smoke callback failed: \(marker)
                Error: \(error)
                """
            }
        case "app-server-callback":
            do {
                summary = try await startAppServerCallbackSmoke(marker: marker, message: message)
            } catch {
                summary = """
                Smoke app-server-callback failed: \(marker)
                Error: \(error)
                """
            }
        case "app-server":
            if state.activeJob != nil {
                summary = "Smoke app-server skipped: a Codex job is already active. Send /codex status or /cancel first."
            } else {
                var smokeConfig = config
                smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
                let request = PromptRequest(promptText: bridgeAppServerSmokePrompt(marker: marker), attachments: [])
                summary = await runBridgeAppServerSmoke(label: "app-server", marker: marker, request: request, config: smokeConfig, requireSuccessToken: true)
            }
        case "inbound-image-check":
            var refs = state.recentMediaRefs ?? []
            if (try? buildInboundImageSmokeRequest(recipient: message.handleId, service: message.service, recentMediaRefs: refs)) == nil,
               let recovered = try? await latestTrustedInboundImageMediaRef(config: config, recipient: message.handleId, service: message.service) {
                refs.append(recovered)
                state.recentMediaRefs = Array(refs.suffix(30))
                try stores.state.save(state)
            }
            do {
                let smoke = try buildInboundImageSmokeRequest(
                    recipient: message.handleId,
                    service: message.service,
                    recentMediaRefs: refs,
                    marker: marker
                )
                summary = await runBridgeAppServerSmoke(
                    label: "inbound-image-check",
                    marker: smoke.marker,
                    request: smoke.request,
                    config: config,
                    requireSuccessToken: true
                )
            } catch {
                summary = """
                Smoke inbound-image-check failed: \(marker)
                Error: \(error)
                """
            }
        case "outbound-image-check":
            if state.activeJob != nil {
                summary = "Smoke outbound-image-check skipped: a Codex job is already active. Send /codex status or /cancel first."
            } else {
                do {
                    try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
                    let attachment = paths.tmpDir.appendingPathComponent("codex-bridge-smoke-\(marker).png")
                    try bridgeSmokePNGData().write(to: attachment)
                    try await sendAttachmentRecording(sink, recipient: message.handleId, service: message.service, filePath: attachment.path)
                    let smoke = try buildOutboundImageSmokeRequest(
                        recipient: message.handleId,
                        service: message.service,
                        recentMediaRefs: state.recentMediaRefs ?? [],
                        marker: marker
                    )
                    let appServerSummary = await runBridgeAppServerSmoke(
                        label: "outbound-image-check",
                        marker: smoke.marker,
                        request: smoke.request,
                        config: config,
                        requireSuccessToken: true
                    )
                    summary = """
                    Smoke outbound-image-check delivery: \(marker)
                    Attachment: \(attachment.path)
                    Evidence: \(lastOutboundSendStatusText())
                    \(appServerSummary)
                    """
                } catch {
                    summary = """
                    Smoke outbound-image-check failed: \(marker)
                    Error: \(error)
                    Evidence: \(lastOutboundSendStatusText())
                    """
                }
            }
        case "chrome", "browser", "computer-use":
            if state.activeJob != nil {
                summary = "Smoke \(subcommand) skipped: a Codex job is already active. Send /codex status or /cancel first."
            } else {
                var smokeConfig = config
                smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
                let request = PromptRequest(promptText: bridgeCapabilitySmokePrompt(capability: subcommand, marker: marker), attachments: [])
                summary = await runBridgeAppServerSmoke(label: subcommand, marker: marker, request: request, config: smokeConfig)
            }
        default:
            summary = "Use /codex smoke text, attachment, bridge-attach, generated-image, automation, callback, app-server-callback, app-server, inbound-image-check, outbound-image-check, chrome, browser, or computer-use."
        }
        _ = try await sink.sendReply(recipient: message.handleId, service: message.service, text: summary)
    }

    private func startGeneratedImageSmoke(marker: String, message: MessageItem) async throws -> String {
        guard state.activeJob == nil else {
            return "Smoke generated-image skipped: \(marker)\nA Codex job is already active. Send /codex status or /cancel first."
        }
        try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
        let artifact = paths.tmpDir.appendingPathComponent("codex-generated-image-\(marker).png")
        try? FileManager.default.removeItem(at: artifact)
        let startedAt = now()
        let batch = PendingBatch(
            handleId: message.handleId,
            service: message.service,
            startedAt: DateCodec.iso(startedAt),
            deadlineAt: DateCodec.iso(startedAt),
            items: [
                MessageItem(
                    rowId: message.rowId,
                    guid: "\(message.guid)-generated-image-smoke",
                    text: bridgeGeneratedImageSmokePrompt(marker: marker, artifactPath: artifact.path),
                    handleId: message.handleId,
                    service: message.service,
                    receivedAt: message.receivedAt,
                    attachments: []
                )
            ]
        )
        try await startPromptBatch(batch)
        return """
        Smoke generated-image started: \(marker)
        Expected artifact: \(artifact.path)
        Success requires Codex to create that file and return BRIDGE_ATTACH for the bridge to deliver.
        """
    }

    private func startBridgeCallbackSmoke(marker: String, message: MessageItem, config: BridgeConfig) async throws -> String {
        if let callback = state.pendingInteractiveCallback, callback.status == "pending" {
            return """
            Smoke callback skipped: \(marker)
            Pending callback: \(callback.callbackId)
            Send a reply for the existing callback or /cancel first.
            """
        }
        guard state.activeJob == nil else {
            return "Smoke callback skipped: \(marker)\nA Codex job is already active. Send /codex status or /cancel first."
        }
        let startedAt = now()
        let callback = PendingInteractiveCallback(
            callbackId: UUID().uuidString,
            jobId: nil,
            jsonRpcId: marker,
            method: bridgeSmokeCallbackMethod,
            recipient: message.handleId,
            service: message.service,
            prompt: "Reply with any short text to complete callback smoke \(marker).",
            createdAt: DateCodec.iso(startedAt),
            expiresAt: DateCodec.iso(startedAt.addingTimeInterval(120)),
            status: "pending"
        )
        try mutateStateAndSave { state in
            state.setPendingInteractiveCallback(callback)
        }
        return """
        Smoke callback pending: \(marker)
        Reply here with any short text within 2 minutes. The next trusted non-command reply should complete this same pending callback instead of starting a new Codex job.
        """
    }

    private func startAppServerCallbackSmoke(marker: String, message: MessageItem) async throws -> String {
        if let callback = state.pendingInteractiveCallback, callback.status == "pending" {
            return """
            Smoke app-server-callback skipped: \(marker)
            Pending callback: \(callback.callbackId)
            Send a reply for the existing callback or /cancel first.
            """
        }
        guard state.activeJob == nil else {
            return "Smoke app-server-callback skipped: \(marker)\nA Codex job is already active. Send /codex status or /cancel first."
        }
        let startedAt = now()
        let batch = PendingBatch(
            handleId: message.handleId,
            service: message.service,
            startedAt: DateCodec.iso(startedAt),
            deadlineAt: DateCodec.iso(startedAt),
            items: [
                MessageItem(
                    rowId: message.rowId,
                    guid: "\(message.guid)-app-server-callback-smoke",
                    text: bridgeAppServerCallbackSmokePrompt(marker: marker),
                    handleId: message.handleId,
                    service: message.service,
                    receivedAt: message.receivedAt,
                    attachments: []
                )
            ]
        )
        try await startPromptBatch(batch)
        return """
        Smoke app-server-callback started: \(marker)
        Wait for Codex to ask for input, then reply here with any short text. Success requires the original app-server turn to complete after that reply.
        """
    }

    private func runBridgeAppServerSmoke(label: String, marker: String, request: PromptRequest, config: BridgeConfig, requireSuccessToken: Bool = false) async -> String {
        let events = BridgeSmokeEventCollector()
        let backend = useDefaultCodexBackend
            ? makeDefaultCodex(config, nil)
            : makeCodex(config)
        do {
            let response = try await backend.invoke(request, sessionId: nil) { event in
                events.record(event)
            }
            if let processPid = events.processPid() {
                _ = terminateProcessTree(rootPid: processPid)
            }
            let responseText = computerUseProbeDetailWithWindowDiagnostics(response.text)
            guard responseText.contains(marker) else {
                return """
                Smoke \(label) failed: \(marker)
                Error: response did not contain marker.
                Thread id: \(response.sessionId ?? events.threadId() ?? "none")
                Turn id: \(events.turnId() ?? "none")
                Response: \(responseText)
                """
            }
            if requireSuccessToken, !responseText.localizedCaseInsensitiveContains("SUCCESS") {
                return """
                Smoke \(label) failed: \(marker)
                Error: response contained marker but did not report SUCCESS.
                Thread id: \(response.sessionId ?? events.threadId() ?? "none")
                Turn id: \(events.turnId() ?? "none")
                Response: \(responseText)
                """
            }
            return """
            Smoke \(label) passed: \(marker)
            Thread id: \(response.sessionId ?? events.threadId() ?? "none")
            Turn id: \(events.turnId() ?? "none")
            Response: \(responseText)
            """
        } catch let error as CodexBackendFailure {
            if let processPid = events.processPid() {
                _ = terminateProcessTree(rootPid: processPid)
            }
            let detail = computerUseProbeDetailWithWindowDiagnostics(error.blockedText ?? error.message)
            return """
            Smoke \(label) failed: \(marker)
            Error: \(detail)
            Thread id: \(events.threadId() ?? "none")
            Turn id: \(events.turnId() ?? "none")
            """
        } catch {
            if let processPid = events.processPid() {
                _ = terminateProcessTree(rootPid: processPid)
            }
            return """
            Smoke \(label) failed: \(marker)
            Error: \(error)
            Thread id: \(events.threadId() ?? "none")
            Turn id: \(events.turnId() ?? "none")
            """
        }
    }

    private func retryLastOutboundSend(config: BridgeConfig) async throws -> String {
        guard let previous = state.lastOutboundSend else {
            return "There is no outbound send to retry."
        }
        guard previous.retryable else {
            return "The last outbound send is not retryable: \(outboundSendStatusText(previous))"
        }
        let sink = makeReplySink(config)
        switch previous.kind {
        case "text":
            guard let body = previous.body, !body.isEmpty else {
                return "The last text send has no recorded body to retry."
            }
            try await sendReplyRecording(sink, recipient: previous.recipient, service: previous.service, text: body)
        case "attachment":
            guard let artifact = previous.artifact, !artifact.isEmpty else {
                return "The last attachment send has no recorded artifact path to retry."
            }
            try await sendAttachmentRecording(sink, recipient: previous.recipient, service: previous.service, filePath: artifact)
        default:
            return "The last outbound send kind is not retryable: \(previous.kind)."
        }
        return "Retried last outbound send: \(lastOutboundSendStatusText())"
    }

    private func codexAutomationRoutesText() -> String {
        let routes = state.automationRoutes ?? []
        var lines: [String] = []
        if let creation = state.automationCreationStatus, creation.phase != "confirmed" {
            lines.append("Automation creation \(creation.phase): \(creation.name ?? creation.automationId ?? "pending")")
            if let sourceRowId = creation.sourceRowId {
                lines.append("Source row: \(sourceRowId)")
            }
            if let path = creation.createdFilePath {
                lines.append("Created file: \(path)")
            }
            if let routeStatus = creation.routeStatus {
                lines.append("Route status: \(routeStatus)")
            }
            if let sendStatus = creation.confirmationSendStatus {
                lines.append("Confirmation send: \(sendStatus)")
            }
            if let failure = creation.failureText {
                lines.append("Failure: \(failure)")
            }
        }
        guard !routes.isEmpty else {
            if !lines.isEmpty { return lines.joined(separator: "\n") }
            return "No Codex automation routes are being bridged to Messages yet."
        }
        if !lines.isEmpty { lines.append("") }
        lines.append("Codex automation routes:")
        for route in routes.sorted(by: { $0.automationId < $1.automationId }) {
            lines.append("- \(route.name) (\(route.automationId)) -> \(route.recipient) via \(route.service); last delivered: \(route.lastDeliveredAt ?? "never")")
        }
        return lines.joined(separator: "\n")
    }

    private func codexStatusText(capabilitySnapshot: CodexCapabilitySnapshot? = nil) -> String {
        var lines = [
            "Codex bridge status:",
            "Active backend: codex app-server",
            "Codex thread id: \(state.codexSession.sessionId ?? "none")"
        ]
        if let threadId = state.codexSession.sessionId, !threadId.isEmpty {
            lines.append("Codex thread link: \(codexThreadDeepLink(threadId))")
        }
        lines += [
            "Last prompt: \(state.codexSession.lastPromptAt ?? "none")",
            "Last completed: \(state.codexSession.lastCompletedAt ?? "none")",
            "Last error: \(state.codexSession.lastErrorAt ?? "none")",
            "Session expires at: \(state.codexSession.expiresAt ?? "none")",
            "Active job: \(state.activeJob?.promptPreview ?? "none")",
            "Active job status: \(state.activeJob?.status ?? "none")",
            "Latest Codex progress: \(state.activeJob?.lastObservedSummary ?? "none")",
            "Latest Codex progress at: \(state.activeJob?.lastProgressAt ?? "none")",
            "Active job thread: \(state.activeJob?.codexSessionId ?? state.codexSession.sessionId ?? "none")",
            "Active job turn: \(state.activeJob?.codexTurnId ?? "none")",
            "Active approval: \(activeApprovalStatusText())",
            "Pending interactive callback: \(pendingInteractiveCallbackStatusText())",
            "Last outbound send: \(lastOutboundSendStatusText())",
            "Recent media refs: \(recentMediaRefsStatusText(state.recentMediaRefs ?? []))"
        ]
        if let capabilitySnapshot {
            lines.append(formatCodexCapabilityCacheLine(capabilitySnapshot))
            lines += formatCodexCapabilityLines(capabilitySnapshot.capabilities)
        } else {
            lines.append("Codex capability cache: unavailable or timed out")
        }
        return lines.joined(separator: "\n")
    }

    private func activeApprovalStatusText() -> String {
        switch state.activeJob?.status {
        case "waitingForUser":
            return "waiting for user input"
        case "waitingForPermission":
            return "waiting for macOS permission recovery"
        default:
            return "none"
        }
    }

    private func pendingInteractiveCallbackStatusText() -> String {
        guard let callback = state.pendingInteractiveCallback else { return "none" }
        var parts = [
            callback.method,
            callback.status,
            "callback \(callback.callbackId)"
        ]
        if let expiresAt = callback.expiresAt {
            parts.append("expires \(expiresAt)")
        }
        if let failure = callback.failureText {
            parts.append("failure \(failure)")
        }
        return parts.joined(separator: "; ")
    }

    private func permissionsCommand(_ parts: [String]) -> String {
        let subcommand = parts.dropFirst().first?.lowercased() ?? "status"
        switch subcommand {
        case "status":
            let config = (try? stores.config.load()) ?? defaultBridgeConfig(paths: paths)
            let broker = config.effectivePermissionBroker
            let status = readPermissionBrokerStatus(paths: paths)
            return """
            Permission broker status:
            Enabled: \(broker.enabled ? "yes" : "no")
            Mode: \(broker.mode)
            Running: \(status?.running == true ? "yes" : "unknown")
            Accessibility trusted: \(status?.accessibilityTrusted == true ? "yes" : "no")
            Last scan: \(status?.lastScanAt ?? "none")
            Last action: \(status?.lastActionAt ?? "none")
            Last update: \(status?.lastSummary ?? "none")
            """
        case "events":
            let events = recentPermissionBrokerEvents(paths: paths, limit: 5)
            guard !events.isEmpty else { return "No permission broker events recorded yet." }
            return "Recent permission broker events:\n" + events.map { event in
                "\(event.timestamp) \(event.kind): \(event.ownerName) \(event.buttonLabel ?? "-") \(event.actionResult)"
            }.joined(separator: "\n")
        case "auto":
            guard parts.count >= 3 else { return "Use /permissions auto on or /permissions auto off." }
            let enabled = parts[2].lowercased() == "on"
            do {
                var config = try stores.config.load()
                var broker = config.effectivePermissionBroker
                broker.enabled = enabled
                config.permissionBroker = broker
                try stores.config.save(config)
                return "Permission broker auto-approval is now \(enabled ? "on" : "off"). Restart the bridge helper if you want the sidecar to pick this up immediately."
            } catch {
                return "I couldn't update permission broker settings: \(error)"
            }
        default:
            return "Use /permissions status, /permissions events, or /permissions auto on|off."
        }
    }

    public func runLocalCommand(_ command: String) -> String {
        let parts = command.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").map(String.init)
        let verb = parts.first?.lowercased() ?? command
        if verb == "/cancel" {
            return cancelActiveJob()
        }
        if verb == "/new" || verb == "/reset" {
            if state.activeJob != nil {
                return "A job is currently running. Send /cancel first if you want to stop it and start fresh."
            }
            let freshSession = CodexSessionState()
            try? mutateStateAndSave { state in
                state.codexSession = freshSession
            }
            return "Started a fresh Codex session for the next message."
        }
        if verb == "/help" {
            return """
            Local bridge commands:
            /status - show bridge cursor and Codex session status
            /codex status - show Codex thread, active job, and capability status
            /codex open - open the active Codex thread in Codex.app
            /codex history - summarize recent app-server thread history
            /codex automations - list Codex automation result routes bridged to Messages
            /codex gates - list remaining bridge gates and exact smoke commands
            /codex retry-last-send - retry the last retryable outbound text or attachment
            /codex smoke text - send a marked text probe and report delivery evidence
            /codex smoke attachment - send a marked image probe and report delivery evidence
            /codex smoke bridge-attach - verify BRIDGE_ATTACH sends media before success text
            /codex smoke generated-image - ask Codex to create and BRIDGE_ATTACH a marked image
            /codex smoke automation - create a paused marked automation and route
            /codex smoke callback - create a pending callback and verify the next reply is routed to it
            /codex smoke app-server-callback - start a real app-server callback turn and reply to finish it
            /codex smoke app-server - verify a normal app-server turn returns a final marked reply
            /codex smoke inbound-image-check - verify the latest trusted inbound image reaches app-server
            /codex smoke outbound-image-check - send an image, then verify "that image" reaches app-server
            /codex smoke chrome|browser|computer-use - verify delegated capability success or blocker text
            /cancel - stop the active Codex job
            /reset or /new - start a fresh Codex session
            /permissions status - show permission broker status
            /permissions events - show recent broker events
            /permissions auto on|off - enable or disable broker auto-clicking
            /help - show this help

            Other slash commands and capability hints are forwarded to Codex.
            """
        }
        if verb == "/codex", parts.dropFirst().first?.lowercased() == "automations" {
            return codexAutomationRoutesText()
        }
        if verb == "/permissions" {
            return permissionsCommand(parts)
        }
        if verb == "/status" {
            return """
            Messages Codex Bridge status:
            Last processed row id: \(state.lastProcessedRowId)
            Last processed guid: \(state.lastProcessedGuid ?? "none")
            Pending batch: \(state.pendingBatch.map { "\($0.items.count) item(s)" } ?? "none")
            Active job: \(state.activeJob?.promptPreview ?? "none")
            Active job status: \(state.activeJob?.status ?? "none")
            Active job last update: \(state.activeJob?.lastObservedSummary ?? "none")
            Pending interactive callback: \(pendingInteractiveCallbackStatusText())
            Last outbound send: \(lastOutboundSendStatusText())
            Queued next batch: \(state.pendingBatch.map { "\($0.items.count) item(s)" } ?? "none")
            Codex session id: \(state.codexSession.sessionId ?? "none")
            Codex thread link: \(state.codexSession.sessionId.map(codexThreadDeepLink) ?? "none")
            Session expires at: \(state.codexSession.expiresAt ?? "none")
            """
        }
        return "Unsupported local command: \(verb)"
    }

    private func startPromptBatch(_ batch: PendingBatch) async throws {
        let config = try stores.config.load()
        let replySink = makeReplySink(config)
        if shouldAskForMissingSourceImage(batch) {
            try await sendReplyRecording(
                replySink,
                recipient: batch.handleId,
                service: batch.service,
                text: "Please send the image you want me to modify, then tell me the edit you want."
            )
            return
        }
        if shouldCreateCodexAutomation(from: batch.items.map(\.text).joined(separator: "\n\n")) {
            try await createAutomationFromMessagesBatch(batch, config: config, replySink: replySink)
            return
        }
        let jobStartedAt = now()
        let jobId = UUID().uuidString
        let activeJob = ActiveJob(
            jobId: jobId,
            guid: batch.items.last?.guid,
            rowId: batch.items.last?.rowId,
            type: "promptBatch",
            receivedAt: DateCodec.iso(jobStartedAt),
            promptPreview: buildBatchPreview(batch),
            recipient: batch.handleId,
            service: batch.service,
            startedAt: DateCodec.iso(jobStartedAt),
            lastProgressAt: nil,
            lastUserUpdateAt: nil,
            lastEventAt: nil,
            codexPid: nil,
            codexSessionId: nil,
            codexTurnId: nil,
            outputPath: nil,
            sessionLogPath: nil,
            status: "starting",
            lastObservedSummary: "Starting.",
            permissionRecoveryAttempts: 0,
            waitingForPermissionSince: nil,
            lastPermissionEventId: nil
        )
        let request = try mutateStateAndSave { state -> PromptRequest in
            var session = state.codexSession
            session.lastPromptAt = DateCodec.iso(jobStartedAt)
            state.codexSession = session
            let request = buildPromptRequest(from: batch, recentMediaRefs: state.recentMediaRefs ?? [])
            state.activeJob = activeJob
            return request
        }
        let longTask = usesLongTaskTimeout(request.promptText)

        let effectiveConfig = configForPrompt(config, request: request)

        if longTask, effectiveConfig.effectiveActiveJobAckEnabled {
            try? await sendReplyRecording(replySink, recipient: batch.handleId, service: batch.service, text: effectiveConfig.effectiveActiveJobAckText)
        }

        activeCodexTask = Task { [weak self] in
            await self?.runActiveCodexJob(jobId: jobId, config: effectiveConfig, request: request, batch: batch)
        }
    }

    private func draftCodexAutomationSpec(for batch: PendingBatch, config: BridgeConfig) async -> CodexAutomationSpec? {
        let userText = batch.items.map(\.text).joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let request = PromptRequest(
            promptText: codexAutomationSpecDraftPrompt(userText: userText, config: config),
            attachments: [],
            threadName: "Draft automation spec"
        )
        do {
            let response = try await makeCodex(config).invoke(request, sessionId: nil, onEvent: nil)
            return parseCodexAutomationSpec(response.text)
        } catch {
            return nil
        }
    }

    private func createAutomationFromMessagesBatch(_ batch: PendingBatch, config: BridgeConfig, replySink: ReplySink) async throws {
        setAutomationCreationStatus(batch: batch, phase: "drafting")
        do {
            let spec = await draftCodexAutomationSpec(for: batch, config: config)
            setAutomationCreationStatus(batch: batch, phase: "creating", name: spec?.name)
            let automation = try createCodexAutomationIfRequested(batch: batch, config: config, paths: paths, now: now(), spec: spec)
            guard let automation else {
                setAutomationCreationStatus(batch: batch, phase: "failed", failureText: "Request looked like automation creation, but no automation was produced.")
                return
            }
            setAutomationCreationStatus(batch: batch, phase: "created", automationId: automation.id, name: automation.name, createdFilePath: automation.path)
            persistAutomationRoute(automation: automation, batch: batch)
            setAutomationCreationStatus(batch: batch, phase: "routed", automationId: automation.id, name: automation.name, createdFilePath: automation.path, routeStatus: "route persisted")
            try await sendReplyRecording(
                replySink,
                recipient: batch.handleId,
                service: batch.service,
                text: "Created Codex automation: \(automation.name)\nSchedule: \(automation.rrule)"
            )
            setAutomationCreationStatus(batch: batch, phase: "confirmed", automationId: automation.id, name: automation.name, createdFilePath: automation.path, routeStatus: "route persisted", confirmationSendStatus: outboundSendStatusText(state.lastOutboundSend))
        } catch {
            setAutomationCreationStatus(batch: batch, phase: "failed", failureText: String(describing: error))
            throw error
        }
    }

    private func setAutomationCreationStatus(batch: PendingBatch, phase: String, automationId: String? = nil, name: String? = nil, createdFilePath: String? = nil, routeStatus: String? = nil, confirmationSendStatus: String? = nil, failureText: String? = nil) {
        let origin = batch.items.last
        let updatedAt = DateCodec.iso(now())
        try? mutateStateAndSave { state in
            state.applyAutomationCreationStatus(
                origin: origin,
                phase: phase,
                automationId: automationId,
                name: name,
                createdFilePath: createdFilePath,
                routeStatus: routeStatus,
                confirmationSendStatus: confirmationSendStatus,
                failureText: failureText,
                updatedAt: updatedAt
            )
        }
    }

    private func persistAutomationRoute(automation: CreatedCodexAutomation, batch: PendingBatch) {
        let origin = batch.items.last
        let route = CodexAutomationRoute(
            automationId: automation.id,
            name: automation.name,
            recipient: batch.handleId,
            service: batch.service,
            createdFromGuid: origin?.guid,
            createdFromRowId: origin?.rowId,
            createdAt: DateCodec.iso(now())
        )
        try? mutateStateAndSave { state in
            state.upsertAutomationRoute(route)
        }
    }

    private func backfillExistingAutomationRoutes(config: BridgeConfig) {
        let targetAutomationId = "morning-news-and-weather-digest"
        guard !(state.automationRoutes ?? []).contains(where: { $0.automationId == targetAutomationId }) else { return }
        guard let recipient = config.effectiveTrustedSenders.first, !recipient.isEmpty else { return }
        let automationPath = paths.codexAutomationsDir.appendingPathComponent("\(targetAutomationId)/automation.toml")
        guard let metadata = automationMetadata(at: automationPath) else { return }
        let route = CodexAutomationRoute(
            automationId: metadata.id,
            name: metadata.name,
            recipient: recipient,
            service: "iMessage",
            createdFromGuid: nil,
            createdFromRowId: nil,
            createdAt: metadata.createdAt ?? DateCodec.iso(now())
        )
        try? mutateStateAndSave { state in
            state.upsertAutomationRoute(route)
        }
    }

    private func deliverCompletedAutomationRuns(config: BridgeConfig) async throws {
        let routes = state.automationRoutes ?? []
        guard !routes.isEmpty else { return }
        let runs = completedCodexAutomationRuns(in: paths.codexSessionsDir, routes: routes)
        guard !runs.isEmpty else { return }
        let replySink = makeReplySink(config)
        let latestRuns = Dictionary(runs.map { ($0.automationId, $0) }, uniquingKeysWith: { _, latest in latest })
        for run in latestRuns.values.sorted(by: { $0.automationId < $1.automationId }) {
            guard let route = state.automationRoutes?.first(where: { $0.automationId == run.automationId }) else { continue }
            guard route.lastDeliveredSessionId != run.sessionId else { continue }
            try await sendReplyRecording(replySink, recipient: route.recipient, service: route.service, text: run.message)
            let deliveredAt = run.completedAt ?? DateCodec.iso(now())
            try mutateStateAndSave { state in
                state.markAutomationRouteDelivered(automationId: run.automationId, sessionId: run.sessionId, deliveredAt: deliveredAt)
            }
        }
    }

    private func sessionIsExpired(config: BridgeConfig) -> Bool {
        guard let sessionId = state.codexSession.sessionId, !sessionId.isEmpty else { return true }
        guard let expiresAt = DateCodec.parse(state.codexSession.expiresAt) else { return false }
        return expiresAt <= now()
    }

    private func runActiveCodexJob(jobId: String, config: BridgeConfig, request: PromptRequest, batch: PendingBatch) async {
        let replySink = makeReplySink(config)
        var currentRequest = request
        var recoveryAttempts = 0
        do {
            while true {
                do {
                    let response = try await invokeCodexWithRecovery(config: config, request: currentRequest, jobId: jobId, replySink: replySink, recipient: batch.handleId, service: batch.service)
                    try await sendOutgoingReply(response, replySink: replySink, recipient: batch.handleId, service: batch.service, config: config, request: currentRequest)
                    break
                } catch let error as CodexBackendFailure where shouldAttemptPermissionRecovery(error, config: config, attempts: recoveryAttempts) {
                    recoveryAttempts += 1
                    let recovered = await waitForPermissionBrokerRecovery(
                        error: error,
                        jobId: jobId,
                        config: config,
                        replySink: replySink,
                        recipient: batch.handleId,
                        service: batch.service,
                        attempt: recoveryAttempts
                    )
                    guard recovered else { throw error }
                    currentRequest = currentRequest.withPermissionRecoveryInstructions()
                }
            }
            updateActiveJob(jobId: jobId) { job in
                job.status = "completed"
                job.lastObservedSummary = "Completed."
            }
            updateCodexSession { session in
                session.lastCompletedAt = DateCodec.iso(now())
                session.lastErrorAt = nil
            }
        } catch let error as CodexBackendFailure {
            if activeJobStatus(jobId: jobId) == "canceling" {
                clearActiveJob(jobId: jobId)
                return
            }
            updateCodexSession { session in
                session.lastErrorAt = DateCodec.iso(now())
            }
            updateActiveJob(jobId: jobId) { job in
                job.status = "failed"
                job.lastObservedSummary = error.blockedText ?? error.message
            }
            try? await sendReplyRecording(replySink, recipient: batch.handleId, service: batch.service, text: failureText(error))
        } catch {
            if activeJobStatus(jobId: jobId) == "canceling" {
                clearActiveJob(jobId: jobId)
                return
            }
            let detail = String(describing: error)
            updateCodexSession { session in
                session.lastErrorAt = DateCodec.iso(now())
            }
            updateActiveJob(jobId: jobId) { job in
                job.status = "failed"
                job.lastObservedSummary = detail
            }
            try? await sendReplyRecording(replySink, recipient: batch.handleId, service: batch.service, text: "I hit an error while working on that:\n\(detail)")
        }
        clearActiveJob(jobId: jobId)
    }

    private func invokeCodexWithRecovery(config: BridgeConfig, request: PromptRequest, jobId: String, replySink: ReplySink, recipient: String, service: String) async throws -> String {
        let expired = sessionIsExpired(config: config)
        if expired {
            resetCodexSession(config: config)
        }
        do {
            return try await invokeCodex(config: config, request: request, sessionId: expired ? nil : state.codexSession.sessionId, jobId: jobId, replySink: replySink, recipient: recipient, service: service)
        } catch let error as CodexBackendFailure {
            if error.blockedText != nil || expired || state.codexSession.sessionId == nil {
                throw error
            }
            resetCodexSession(config: config)
            return try await invokeCodex(config: config, request: request, sessionId: nil, jobId: jobId, replySink: replySink, recipient: recipient, service: service)
        }
    }

    private func invokeCodex(config: BridgeConfig, request: PromptRequest, sessionId: String?, jobId: String, replySink: ReplySink, recipient: String, service: String) async throws -> String {
        let backend: any CodexBackend = useDefaultCodexBackend
            ? makeDefaultCodex(config, interactiveCallbackResponder(jobId: jobId, replySink: replySink, recipient: recipient, service: service, config: config))
            : makeCodex(config)
        let result = try await backend.invoke(request, sessionId: sessionId) { [weak self] event in
            guard let self else { return }
            self.handleCodexStreamEvent(event, jobId: jobId, config: config, replySink: replySink, recipient: recipient, service: service)
        }
        updateCodexSession { session in
            session.sessionId = result.sessionId ?? session.sessionId
            if session.startedAt == nil { session.startedAt = DateCodec.iso(now()) }
            session.expiresAt = DateCodec.iso(now().addingTimeInterval(Double(config.sessionTtlMs) / 1000))
        }
        updateActiveJob(jobId: jobId) { job in
            job.codexSessionId = result.sessionId ?? job.codexSessionId
            job.outputPath = result.outputPath
            job.status = "running"
        }
        return result.text
    }

    private func sendOutgoingReply(_ text: String, replySink: ReplySink, recipient: String, service: String, config: BridgeConfig, request: PromptRequest) async throws {
        let safeText = safeUserVisibleText(text)
        let outgoing = prepareOutgoingReply(safeText, config: config)
        if !outgoing.attachments.isEmpty {
            for attachment in outgoing.attachments {
                do {
                    try await sendAttachmentRecording(replySink, recipient: recipient, service: service, filePath: attachment)
                } catch {
                    throw StoreError.validation("Could not send attachment \(attachment): \(error)")
                }
            }
            if !outgoing.text.isEmpty {
                _ = try await replySink.sendReply(recipient: recipient, service: service, text: outgoing.text)
            }
        } else {
            if !outgoing.text.isEmpty {
                try await sendReplyRecording(replySink, recipient: recipient, service: service, text: outgoing.text)
            }
            if outgoing.text.isEmpty {
                try await sendReplyRecording(replySink, recipient: recipient, service: service, text: safeText)
            }
        }
    }

    private func sendReplyRecording(_ replySink: ReplySink, recipient: String, service: String, text: String) async throws {
        let attemptId = recordOutboundSendStarted(kind: "text", recipient: recipient, service: service, artifact: nil, body: text)
        do {
            let evidence = try await replySink.sendReply(recipient: recipient, service: service, text: text)
            recordOutboundSendCompleted(attemptId: attemptId, evidence: evidence)
        } catch {
            recordOutboundSendFailed(attemptId: attemptId, error: error, retryable: true)
            throw error
        }
    }

    private func sendAttachmentRecording(_ replySink: ReplySink, recipient: String, service: String, filePath: String) async throws {
        let attemptId = recordOutboundSendStarted(kind: "attachment", recipient: recipient, service: service, artifact: filePath)
        do {
            let evidence = try await replySink.sendAttachment(recipient: recipient, service: service, filePath: filePath)
            recordOutboundSendCompleted(attemptId: attemptId, evidence: evidence)
            recordOutboundMediaRef(recipient: recipient, service: service, filePath: filePath, evidence: evidence)
        } catch {
            recordOutboundSendFailed(attemptId: attemptId, error: error, retryable: true)
            throw error
        }
    }

    private func recordOutboundSendStarted(kind: String, recipient: String, service: String, artifact: String?, body: String? = nil) -> String {
        let attemptId = UUID().uuidString
        try? mutateStateAndSave { state in
            state.lastOutboundSend = OutboundSendRecord(
                attemptId: attemptId,
                kind: kind,
                recipient: recipient,
                service: service,
                artifact: artifact,
                body: body,
                status: "queued",
                startedAt: DateCodec.iso(now()),
                retryable: false
            )
        }
        return attemptId
    }

    private func recordOutboundSendCompleted(attemptId: String, evidence: OutboundDeliveryEvidence) {
        try? mutateStateAndSave { state in
            guard state.lastOutboundSend?.attemptId == attemptId else { return }
            state.lastOutboundSend?.status = outboundSendCompletedStatus(evidence)
            state.lastOutboundSend?.completedAt = DateCodec.iso(now())
            state.lastOutboundSend?.retryable = false
            state.lastOutboundSend?.evidence = evidence
            state.lastOutboundSend?.error = nil
        }
    }

    private func recordOutboundSendFailed(attemptId: String, error: Error, retryable: Bool) {
        try? mutateStateAndSave { state in
            guard state.lastOutboundSend?.attemptId == attemptId else { return }
            state.lastOutboundSend?.status = "failed"
            state.lastOutboundSend?.completedAt = DateCodec.iso(now())
            state.lastOutboundSend?.retryable = retryable
            if let failure = error as? OutboundDeliveryFailure {
                state.lastOutboundSend?.evidence = failure.evidence
                state.lastOutboundSend?.error = failure.description
            } else {
                state.lastOutboundSend?.error = String(describing: error)
            }
        }
    }

    private func outboundSendCompletedStatus(_ evidence: OutboundDeliveryEvidence) -> String {
        if let error = evidence.dbError, error != 0 { return "failed" }
        if let rowId = evidence.dbRowId, rowId > 0 {
            if let delivered = evidence.dateDelivered, delivered > 0 { return "delivered" }
            return "dbObserved"
        }
        return "sentToMessages"
    }

    private func lastOutboundSendStatusText() -> String {
        outboundSendStatusText(state.lastOutboundSend)
    }

    private func recordInboundMediaRefs(_ message: MessageItem) {
        for attachment in message.attachments where attachment.kind == "image" {
            guard let path = attachment.absolutePath else { continue }
            appendRecentMediaRef(RecentMediaRef(
                direction: "inbound",
                rowId: message.rowId,
                handleId: message.handleId,
                service: message.service,
                path: path,
                transferName: attachment.transferName,
                kind: attachment.kind,
                createdAt: message.receivedAt ?? DateCodec.iso(now()),
                exists: FileManager.default.fileExists(atPath: path)
            ))
        }
    }

    private func recordOutboundMediaRef(recipient: String, service: String, filePath: String, evidence: OutboundDeliveryEvidence) {
        guard imageKindForPath(filePath) == "image" else { return }
        appendRecentMediaRef(RecentMediaRef(
            direction: "outbound",
            rowId: evidence.dbRowId,
            handleId: recipient,
            service: service,
            path: filePath,
            transferName: URL(fileURLWithPath: filePath).lastPathComponent,
            kind: "image",
            createdAt: DateCodec.iso(now()),
            exists: FileManager.default.fileExists(atPath: filePath)
        ))
    }

    private func appendRecentMediaRef(_ ref: RecentMediaRef) {
        try? mutateStateAndSave { state in
            var refs = state.recentMediaRefs ?? []
            refs.removeAll { $0.direction == ref.direction && $0.rowId == ref.rowId && $0.path == ref.path && $0.handleId == ref.handleId }
            refs.append(ref)
            state.recentMediaRefs = Array(refs.suffix(30))
        }
    }

    private func shouldAskForMissingSourceImage(_ batch: PendingBatch) -> Bool {
        guard batch.items.allSatisfy({ $0.attachments.isEmpty }) else { return false }
        let text = batch.items.map(\.text).joined(separator: "\n")
        guard promptReferencesPreviousImage(text) else { return false }
        return latestUsableImageRef(for: batch.handleId, service: batch.service, recentMediaRefs: state.recentMediaRefs ?? []) == nil
    }

    private func imageKindForPath(_ path: String) -> String? {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "heic", "tif", "tiff", "bmp", "webp"]
        return imageExtensions.contains(URL(fileURLWithPath: path).pathExtension.lowercased()) ? "image" : nil
    }

    private func hasUsableRecentMedia(direction: String, recipient: String, service: String) -> Bool {
        state.recentMediaRefs?.contains(where: { ref in
            ref.direction == direction &&
                ref.handleId == recipient &&
                ref.service == service &&
                ref.kind == "image" &&
                ref.exists &&
                appServerSupportedLocalImagePath(ref.path) &&
                FileManager.default.fileExists(atPath: ref.path)
        }) == true
    }

    private func shouldAttemptPermissionRecovery(_ error: CodexBackendFailure, config: BridgeConfig, attempts: Int) -> Bool {
        let broker = config.effectivePermissionBroker
        guard broker.enabled, attempts < broker.maxRecoveryAttempts else { return false }
        guard let blocked = error.blockedText ?? Optional(error.message) else { return false }
        return isRecoverablePermissionBlock(blocked)
    }

    private func waitForPermissionBrokerRecovery(error: CodexBackendFailure, jobId: String, config: BridgeConfig, replySink: ReplySink, recipient: String, service: String, attempt: Int) async -> Bool {
        let start = now()
        let blocked = error.blockedText ?? error.message
        updateActiveJob(jobId: jobId) { job in
            job.status = "waitingForPermission"
            job.permissionRecoveryAttempts = attempt
            job.waitingForPermissionSince = DateCodec.iso(start)
            job.lastObservedSummary = blocked
        }
        try? await sendReplyRecording(
            replySink,
            recipient: recipient,
            service: service,
            text: "A macOS permission prompt appears to be blocking this job. I’m letting the permission broker handle it, then I’ll retry automatically.\n\(blocked)"
        )

        let timeout = Double(config.effectivePermissionBroker.recoveryTimeoutMs) / 1000
        var lastEventId: String?
        while now().timeIntervalSince(start) < timeout {
            if activeJobStatus(jobId: jobId) == "canceling" { return false }
            let events = recentPermissionBrokerEvents(paths: paths, limit: 10)
            if let event = events.reversed().first(where: { event in
                DateCodec.parse(event.timestamp).map { $0 >= start } == true && ["clicked", "wouldClick"].contains(event.kind)
            }) {
                lastEventId = event.eventId
                updateActiveJob(jobId: jobId) { job in
                    job.status = "running"
                    job.lastPermissionEventId = event.eventId
                    job.lastObservedSummary = "Permission broker \(event.actionResult). Retrying."
                    job.waitingForPermissionSince = nil
                }
                try? await sendReplyRecording(replySink, recipient: recipient, service: service, text: "The permission broker handled a macOS prompt. I’m retrying the job now.")
                return true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        updateActiveJob(jobId: jobId) { job in
            job.status = "failed"
            job.lastPermissionEventId = lastEventId
            job.lastObservedSummary = "Timed out waiting for the permission broker."
        }
        return false
    }

    private func handleCodexStreamEvent(_ event: CodexStreamEvent, jobId: String, config: BridgeConfig, replySink: ReplySink, recipient: String, service: String) {
        let message: String?
        let immediate: Bool
        switch event {
        case .processStarted(let pid):
            updateActiveJob(jobId: jobId) { job in
                job.codexPid = pid
                job.status = "running"
                job.lastEventAt = DateCodec.iso(now())
            }
            return
        case .sessionStarted(let sessionId):
            updateActiveJob(jobId: jobId) { job in
                job.codexSessionId = sessionId
                job.lastEventAt = DateCodec.iso(now())
            }
            updateCodexSession { session in
                session.sessionId = sessionId
            }
            return
        case .turnStarted(let turnId):
            updateActiveJob(jobId: jobId) { job in
                job.codexTurnId = turnId
                job.lastEventAt = DateCodec.iso(now())
                job.lastObservedSummary = "Codex turn started."
            }
            return
        case .progress(let text):
            message = text
            immediate = false
        case .milestone(let text):
            message = text
            immediate = shouldSendMilestone(jobId: jobId, config: config)
        case .question(let text):
            message = text
            immediate = true
            updateActiveJob(jobId: jobId) { $0.status = "waitingForUser" }
        case .blocker(let text):
            message = safeUserVisibleBlockerText(text) ?? internalBridgeLeakReplacement
            immediate = true
            updateActiveJob(jobId: jobId) { $0.status = isRecoverablePermissionBlock(message ?? "") ? "waitingForPermission" : "failed" }
        }
        guard let message, shouldSendProgress(jobId: jobId, config: config, immediate: immediate) else {
            if let message {
                updateActiveJob(jobId: jobId) { job in
                    job.lastObservedSummary = message
                    job.lastEventAt = DateCodec.iso(now())
                }
            }
            return
        }
        updateActiveJob(jobId: jobId) { job in
            job.lastObservedSummary = message
            job.lastProgressAt = DateCodec.iso(now())
            job.lastUserUpdateAt = DateCodec.iso(now())
            job.lastEventAt = DateCodec.iso(now())
        }
        Task {
            try? await self.sendReplyRecording(replySink, recipient: recipient, service: service, text: message)
        }
    }

    private func shouldSendProgress(jobId: String, config: BridgeConfig, immediate: Bool) -> Bool {
        immediate
    }

    private func shouldSendMilestone(jobId: String, config: BridgeConfig) -> Bool {
        false
    }

    private func updateActiveJob(jobId: String, _ update: (inout ActiveJob) -> Void) {
        let stateToSave = stateBox.mutate { state -> BridgeState? in
            guard var job = state.activeJob, job.jobId == jobId else { return nil }
            update(&job)
            state.activeJob = job
            return state
        }
        if let stateToSave {
            try? stores.state.save(stateToSave)
        }
    }

    private func updateCodexSession(_ update: (inout CodexSessionState) -> Void) {
        try? mutateStateAndSave { state in
            var session = state.codexSession
            update(&session)
            state.codexSession = session
        }
    }

    private func resetCodexSession(config: BridgeConfig) {
        let fresh = CodexSessionState(
            startedAt: DateCodec.iso(now()),
            expiresAt: DateCodec.iso(now().addingTimeInterval(Double(config.sessionTtlMs) / 1000))
        )
        try? mutateStateAndSave { state in
            state.codexSession = fresh
        }
    }

    private func activeJobStatus(jobId: String) -> String? {
        let snapshot = stateBox.snapshot()
        guard snapshot.activeJob?.jobId == jobId else { return nil }
        return snapshot.activeJob?.status
    }

    private func clearActiveJob(jobId: String) {
        let cleared = stateBox.mutate { state -> Bool in
            guard state.activeJob?.jobId == jobId else { return false }
            state.activeJob = nil
            return true
        }
        guard cleared else { return }
        activeCodexTask = nil
        try? saveStateSnapshot()
    }

    private func cancelActiveJob() -> String {
        let transition = stateBox.mutate { state -> CancelTransition in
            var snapshots: [BridgeState] = []
            let callbackWasPending = state.pendingInteractiveCallback?.status == "pending"
            if state.cancelPendingInteractiveCallback(failureText: "Canceled by /cancel from Messages.") {
                snapshots.append(state)
            }
            guard let job = state.activeJob else {
                state.clearPendingInteractiveCallback()
                snapshots.append(state)
                return CancelTransition(
                    message: callbackWasPending ? "Canceled the pending Codex prompt." : "No active job is running.",
                    processPid: nil,
                    cancelTask: false,
                    snapshots: snapshots
                )
            }
            state.activeJob?.status = "canceling"
            if let pid = job.codexPid {
                state.clearPendingInteractiveCallback()
                snapshots.append(state)
                return CancelTransition(
                    message: callbackWasPending ? "Canceling the active Codex job and pending prompt." : "Canceling the active Codex job.",
                    processPid: pid,
                    cancelTask: true,
                    snapshots: snapshots
                )
            }
            state.activeJob = nil
            state.clearPendingInteractiveCallback()
            snapshots.append(state)
            return CancelTransition(
                message: callbackWasPending ? "Canceled the active Codex job and pending prompt." : "Canceled the active Codex job.",
                processPid: nil,
                cancelTask: true,
                snapshots: snapshots
            )
        }
        if let pid = transition.processPid {
            _ = terminateProcessTree(rootPid: pid)
        }
        if transition.cancelTask {
            activeCodexTask?.cancel()
        }
        for snapshot in transition.snapshots {
            try? stores.state.save(snapshot)
        }
        return transition.message
    }

    private func recoverActiveJobOnStartup() {
        guard var job = state.activeJob else { return }
        if let pid = job.codexPid, processIsRunning(pid) {
            job.status = job.status ?? "running"
            job.lastObservedSummary = job.lastObservedSummary ?? "Recovered a running Codex process after helper restart."
            state.activeJob = job
        } else {
            job.status = "failed"
            job.lastObservedSummary = "The helper restarted while this job was active, and the Codex process is no longer running."
            state.activeJob = job
        }
    }

    private func recoverDetachedActiveJobIfNeeded(config: BridgeConfig) async throws {
        guard activeCodexTask == nil, var job = state.activeJob, let pid = job.codexPid, !processIsRunning(pid) else { return }
        let lastActivity = DateCodec.parse(job.lastEventAt) ?? DateCodec.parse(job.startedAt) ?? now()
        guard now().timeIntervalSince(lastActivity) >= 30 else { return }
        job.status = "failed"
        job.lastObservedSummary = "The active Codex process is no longer running."
        state.activeJob = nil
        try stores.state.save(state)
        if let recipient = job.recipient, let service = job.service {
            try? await sendReplyRecording(
                makeReplySink(config),
                recipient: recipient,
                service: service,
                text: "That active job stopped before it could finish, so I cleared it. Please send the request again."
            )
        }
    }

    private func processIsRunning(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }
}

private func interactiveCallbackPrompt(method: String, params: [String: Any]?) -> String {
    if method == "item/tool/requestUserInput" {
        if let questions = params?["questions"] as? [[String: Any]], !questions.isEmpty {
            return questions.map { question in
                let header = question["header"] as? String
                let text = question["question"] as? String ?? question["prompt"] as? String ?? "Codex is asking for input."
                return [header, text].compactMap { $0 }.joined(separator: ": ")
            }.joined(separator: "\n")
        }
        if let prompt = params?["prompt"] as? String, !prompt.isEmpty {
            return prompt
        }
    }
    if method == "mcpServer/elicitation/request" {
        if let message = params?["message"] as? String, !message.isEmpty {
            return message
        }
        if let request = params?["request"] as? [String: Any],
           let message = request["message"] as? String,
           !message.isEmpty {
            return message
        }
    }
    return "Codex is asking for input."
}

private func interactiveCallbackSuccessResponse(method: String, answer: String, params: [String: Any]?) -> [String: Any] {
    if method == "item/tool/requestUserInput" {
        let questionIds = ((params?["questions"] as? [[String: Any]]) ?? []).compactMap { $0["id"] as? String }
        let ids = questionIds.isEmpty ? ["response"] : questionIds
        let answers = Dictionary(uniqueKeysWithValues: ids.map { ($0, ["answers": [answer]]) })
        return ["result": ["answers": answers]]
    }
    if method == "mcpServer/elicitation/request" {
        return [
            "result": [
                "action": "accept",
                "content": ["response": answer],
                "_meta": NSNull()
            ]
        ]
    }
    return ["result": [:]]
}

private func interactiveCallbackCancelResponse(method: String, answer: String?, params: [String: Any]?) -> [String: Any] {
    if method == "item/tool/requestUserInput" {
        return ["result": ["answers": [:]]]
    }
    if method == "mcpServer/elicitation/request" {
        return [
            "result": [
                "action": "cancel",
                "content": NSNull(),
                "_meta": NSNull()
            ]
        ]
    }
    return ["result": [:]]
}

private func runAsyncBlocking<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = LockedResultBox<T>()
    Task {
        do {
            box.set(.success(try await operation()))
        } catch {
            box.set(.failure(error))
        }
        semaphore.signal()
    }
    semaphore.wait()
    return try box.get()
}

private final class LockedResultBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<T, Error>?

    func set(_ value: Result<T, Error>) {
        lock.lock()
        result = value
        lock.unlock()
    }

    func get() throws -> T {
        lock.lock()
        defer { lock.unlock() }
        return try result!.get()
    }
}

private struct CancelTransition {
    var message: String
    var processPid: Int32?
    var cancelTask: Bool
    var snapshots: [BridgeState]
}

public func bridgeLocalCommandName(_ text: String) -> String? {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if ["/codex status", "/codex open", "/codex history", "/codex automations", "/codex gates", "/codex retry-last-send"].contains(normalized) || isCodexSmokeCommand(normalized) {
        return "/codex"
    }
    let command = normalized.split(separator: " ").first.map(String.init)
    guard let command, command != "/codex", BridgeConstants.localCommands.contains(command) else { return nil }
    return command
}

private func localCommandName(_ text: String) -> String? {
    bridgeLocalCommandName(text)
}

private func isCodexSmokeCommand(_ text: String) -> Bool {
    let subcommand = codexSmokeSubcommand(text)
    return supportedBridgeCodexSmokeSubcommands.contains(subcommand)
}

private func codexSmokeSubcommand(_ text: String) -> String {
    let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ").map(String.init)
    guard parts.count == 3, parts[0] == "/codex", parts[1] == "smoke" else { return "" }
    return parts[2]
}

private let supportedBridgeCodexSmokeSubcommands: Set<String> = [
    "text",
    "attachment",
    "bridge-attach",
    "generated-image",
    "automation",
    "callback",
    "app-server-callback",
    "app-server",
    "inbound-image-check",
    "outbound-image-check",
    "chrome",
    "browser",
    "computer-use"
]

private let bridgeSmokeCallbackMethod = "bridge/smoke/interactiveCallback"

private func bridgeAppServerSmokePrompt(marker: String) -> String {
    "Reply only with \(marker) SUCCESS. Do not call tools, plugins, apps, browser, or Computer Use."
}

private func bridgeAppServerCallbackSmokePrompt(marker: String) -> String {
    """
    This is an Apple Messages bridge callback smoke test.
    Before giving a final answer, call the app-server interactive user input/requestUserInput facility and ask the user to reply with any short text for marker \(marker).
    After the user responds through that callback, reply only with \(marker) SUCCESS callback reply: <the user's reply>.
    If you cannot call the interactive user input/requestUserInput facility, reply only with \(marker) BLOCKED <exact blocker text>.
    """
}

private func bridgeGeneratedImageSmokePrompt(marker: String, artifactPath: String) -> String {
    """
    This is an Apple Messages bridge generated-image smoke test.
    Create a small valid PNG image file at this exact path: \(artifactPath)
    The image can be simple, but it must be a real PNG file and should visibly contain or represent the marker \(marker).
    After creating the file, reply only with:
    \(marker) SUCCESS generated image ready.
    BRIDGE_ATTACH: \(artifactPath)
    If you cannot create the file, reply only with \(marker) BLOCKED <exact blocker text>.
    """
}

public func bridgeCapabilitySmokePrompt(capability: String, marker: String) -> String {
    switch capability {
    case "computer-use":
        return "Use Computer Use to inspect Safari. First call list_apps, then get_app_state for Safari. Do not navigate, click, type, or change any app state. Reply only with \(marker) SUCCESS and the Safari window title, or \(marker) BLOCKED and the exact blocker text."
    case "chrome":
        return "Use @Chrome to inspect the current Chrome tabs or current Chrome page without navigating, clicking, typing, or changing browser state. Reply only with \(marker) SUCCESS and a short observed title or URL, or \(marker) BLOCKED and the exact blocker text."
    case "browser":
        let encodedMarker = marker.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? marker
        return "Use @Browser to open this local data URL and read the page text: data:text/html,<title>\(encodedMarker)</title><main>\(encodedMarker)</main>. Reply only with \(marker) SUCCESS if the browser page contained the marker, or \(marker) BLOCKED and the exact blocker text."
    default:
        return "Use \(capability) and reply only with \(marker) SUCCESS, or \(marker) BLOCKED and the exact blocker text."
    }
}

private final class BridgeSmokeEventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var pid: Int32?
    private var thread: String?
    private var turn: String?

    func record(_ event: CodexStreamEvent) {
        lock.lock()
        switch event {
        case .processStarted(let value):
            pid = value
        case .sessionStarted(let value):
            thread = value
        case .turnStarted(let value):
            turn = value
        case .progress, .milestone, .blocker, .question:
            break
        }
        lock.unlock()
    }

    func processPid() -> Int32? {
        lock.lock()
        defer { lock.unlock() }
        return pid
    }

    func threadId() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return thread
    }

    func turnId() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return turn
    }
}

public func bridgeSmokePNGData() throws -> Data {
    let encoded = "iVBORw0KGgoAAAANSUhEUgAAANsAAAAhCAIAAADf6EloAAABD0lEQVR42u3cTQ6CMBAGUA7hxo0b11zNw7r2LnoAiNrp30De5FsZWkp5JrUQl9dtFcmTxRRIRpFvpWYXkYpIpYhUhxd5ud5/Zttdv1bb5rFzxZrHRlhUsfH802HRuYr6+XJMeMaIJJJIIomsERkbR2ymBhwTc1OprXnPRV+efjNW6Ti4jiSSSCKJJJLIY4qs/KRVz0QSSSSRRCYROWD3J4nIfjtNlbs/SUTG7mDpjBFJJJFEElkjcsCaI9s6stVV9Ftrzr32Y/+yIZJIIokksvUmPpGZRZ7kmQ2RRBJJ5BlFpn2X7hzvR46c51Y7Tf3uKZFEEkkkkTGRSk2pHZHr4ykyPkQKkSJFIkX8W5/ITj4lX83iLEYIcQAAAABJRU5ErkJggg=="
    guard let data = Data(base64Encoded: encoded) else {
        throw StoreError.validation("Could not decode smoke PNG fixture.")
    }
    return data
}

private func failureText(_ error: CodexBackendFailure) -> String {
    if let blocked = error.blockedText {
        let safeBlocked = safeUserVisibleBlockerText(blocked) ?? "The bridge suppressed an unsafe internal diagnostic instead of texting it."
        return "Codex was blocked by a local permission or automation request:\n\(safeBlocked)"
    }
    if error.timedOut {
        return "I hit the bridge timeout while working on that. Please try again."
    }
    return "I hit an error while working on that. Please try again."
}

public func configForPrompt(_ config: BridgeConfig, request: PromptRequest) -> BridgeConfig {
    guard usesLongTaskTimeout(request.promptText) else { return config }
    var adjusted = config
    adjusted.timeoutMs = max(config.timeoutMs, config.sessionTtlMs)
    return adjusted
}

public func usesLongTaskTimeout(_ promptText: String) -> Bool {
    let text = promptText.lowercased()
    let longTaskHints = [
        "long-running",
        "long running",
        "until ",
        "keep going",
        "keep working",
        "play ",
        "monitor ",
        "watch ",
        "wait ",
        "run for",
        "for an hour",
        "for 1 hour",
        "for two hours",
        "for 2 hours",
        "once you",
        "when you",
        "after you"
    ]
    return longTaskHints.contains { text.contains($0) }
}

public let missingInboundAttachmentDeferWindowSeconds: TimeInterval = 30

public func shouldDeferMessageForMissingAttachments(
    _ message: MessageItem,
    now: Date,
    deferWindowSeconds: TimeInterval = missingInboundAttachmentDeferWindowSeconds
) -> Bool {
    guard !message.attachments.isEmpty,
          let receivedAt = message.receivedAt.flatMap(DateCodec.parse),
          now.timeIntervalSince(receivedAt) <= deferWindowSeconds else {
        return false
    }
    return message.attachments.contains { attachment in
        guard let path = attachment.absolutePath else { return false }
        return !FileManager.default.fileExists(atPath: path)
    }
}

public func outgoingAttachmentsWereRequested(in promptText: String) -> Bool {
    let text = promptText.lowercased()
    let attachmentRequestHints = [
        "send me ",
        "send back",
        "send it back",
        "send over",
        "send it over",
        "send this over",
        "send that over",
        "send the file",
        "send a file",
        "send an attachment",
        "send the attachment",
        "send the image",
        "send an image",
        "send a screenshot",
        "attach ",
        "as an attachment",
        "return an attachment",
        "return the attachment",
        "return the file",
        "return it as a file",
        "text me the file",
        "share the file",
        "share it back"
    ]
    return attachmentRequestHints.contains { text.contains($0) }
}
