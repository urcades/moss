import Foundation

public final class BridgeService: @unchecked Sendable {
    private let paths: RuntimePaths
    private let stores: RuntimeStores
    private let makeSource: (BridgeConfig) -> MessageSource
    private let makeReplySink: (BridgeConfig) -> ReplySink
    private let makeCodex: (BridgeConfig) -> any CodexBackend
    private let now: () -> Date
    private var state: BridgeState
    private var stopped = false
    private var queue: [Job] = []
    private var activeCodexTask: Task<Void, Never>?
    private let stateLock = NSLock()

    public init(
        paths: RuntimePaths = .current(),
        stores: RuntimeStores? = nil,
        makeSource: @escaping (BridgeConfig) -> MessageSource,
        makeReplySink: @escaping (BridgeConfig) -> ReplySink,
        makeCodex: @escaping (BridgeConfig) -> any CodexBackend,
        now: @escaping () -> Date = Date.init
    ) {
        self.paths = paths
        self.stores = stores ?? RuntimeStores(paths: paths)
        self.makeSource = makeSource
        self.makeReplySink = makeReplySink
        self.makeCodex = makeCodex
        self.now = now
        self.state = defaultBridgeState()
    }

    public convenience init(paths: RuntimePaths = .current()) {
        self.init(
            paths: paths,
            makeSource: { SQLiteMessageSource(dbPath: $0.messagesDbPath, trustedSenders: $0.effectiveTrustedSenders) },
            makeReplySink: { AppleMessagesReplySink(osascriptCommand: $0.osascriptCommand, chunkSize: $0.chunkSize, messagesDbPath: $0.messagesDbPath) },
            makeCodex: { CodexAppServerBackend(config: $0, paths: paths) }
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
        try await recoverDetachedActiveJobIfNeeded(config: config)
        let messages = try await makeSource(config).fetchNewMessages(afterRowId: state.lastProcessedRowId)
        for message in messages {
            state.lastProcessedGuid = message.guid
            state.lastProcessedRowId = message.rowId
            processIncoming(config: config, message: message)
        }
        try await syncPendingBatch(config: config)
        try await drainQueue()
        try stores.state.save(state)
    }

    private func processIncoming(config: BridgeConfig, message: MessageItem) {
        if state.activeJob != nil {
            if let command = localCommandName(message.text), message.attachments.isEmpty {
                queue.append(.localCommand(command, message))
            } else {
                appendToPendingBatch(config: config, message: message)
            }
            return
        }
        if let command = localCommandName(message.text), message.attachments.isEmpty {
            finalizePendingBatch()
            queue.append(.localCommand(command, message))
            return
        }
        appendToPendingBatch(config: config, message: message)
    }

    private func appendToPendingBatch(config: BridgeConfig, message: MessageItem) {
        let messageDate = DateCodec.parse(message.receivedAt) ?? now()
        if state.pendingBatch == nil {
            state.pendingBatch = PendingBatch(
                handleId: message.handleId,
                service: message.service,
                startedAt: DateCodec.iso(messageDate),
                deadlineAt: DateCodec.iso(messageDate.addingTimeInterval(Double(config.batchWindowMs) / 1000)),
                items: [message]
            )
            return
        }
        if let deadline = DateCodec.parse(state.pendingBatch?.deadlineAt), messageDate > deadline {
            finalizePendingBatch()
            state.pendingBatch = PendingBatch(
                handleId: message.handleId,
                service: message.service,
                startedAt: DateCodec.iso(messageDate),
                deadlineAt: DateCodec.iso(messageDate.addingTimeInterval(Double(config.batchWindowMs) / 1000)),
                items: [message]
            )
            return
        }
        state.pendingBatch?.items.append(message)
        state.pendingBatch?.deadlineAt = DateCodec.iso(messageDate.addingTimeInterval(Double(config.batchWindowMs) / 1000))
    }

    @discardableResult
    private func finalizePendingBatch() -> PendingBatch? {
        guard let batch = state.pendingBatch else { return nil }
        queue.append(.promptBatch(batch))
        state.pendingBatch = nil
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
        while !queue.isEmpty {
            let index: Int
            if state.activeJob != nil {
                guard let localCommandIndex = queue.firstIndex(where: {
                    if case .localCommand = $0 { return true }
                    return false
                }) else {
                    return
                }
                index = localCommandIndex
            } else {
                index = 0
            }
            let job = queue.remove(at: index)
            switch job {
            case .localCommand(let command, let message):
                try await handleLocalCommand(command, message: message)
            case .promptBatch(let batch):
                if state.activeJob == nil {
                    try await startPromptBatch(batch)
                }
            }
        }
    }

    private func handleLocalCommand(_ command: String, message: MessageItem) async throws {
        let config = try stores.config.load()
        let text = command == "/codex"
            ? try await runCodexCommand(message.text, config: config)
            : runLocalCommand(message.text)
        try await makeReplySink(config).sendReply(recipient: message.handleId, service: message.service, text: text)
        try stores.state.save(state)
    }

    private func runCodexCommand(_ command: String, config: BridgeConfig) async throws -> String {
        let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "/codex status":
            let snapshot = await cachedCodexCapabilities(command: config.codex.command, paths: paths)
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
        default:
            return "Use /codex status, /codex open, or /codex history."
        }
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
            "Active approval: \(activeApprovalStatusText())"
        ]
        if let capabilitySnapshot {
            lines.append(formatCodexCapabilityCacheLine(capabilitySnapshot))
            lines += formatCodexCapabilityLines(capabilitySnapshot.capabilities)
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
            state.codexSession = CodexSessionState()
            return "Started a fresh Codex session for the next message."
        }
        if verb == "/help" {
            return """
            Local bridge commands:
            /status - show bridge cursor and Codex session status
            /codex status - show Codex thread, active job, and capability status
            /codex open - open the active Codex thread in Codex.app
            /codex history - summarize recent app-server thread history
            /cancel - stop the active Codex job
            /reset or /new - start a fresh Codex session
            /permissions status - show permission broker status
            /permissions events - show recent broker events
            /permissions auto on|off - enable or disable broker auto-clicking
            /help - show this help

            Other slash commands and capability hints are forwarded to Codex.
            """
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
        state.codexSession.lastPromptAt = DateCodec.iso(now())
        let request = buildPromptRequest(from: batch)
        let longTask = usesLongTaskTimeout(request.promptText)
        let jobId = UUID().uuidString
        state.activeJob = ActiveJob(
            jobId: jobId,
            guid: batch.items.last?.guid,
            rowId: batch.items.last?.rowId,
            type: "promptBatch",
            receivedAt: DateCodec.iso(now()),
            promptPreview: buildBatchPreview(batch),
            recipient: batch.handleId,
            service: batch.service,
            startedAt: DateCodec.iso(now()),
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
        try stores.state.save(state)

        let effectiveConfig = configForPrompt(config, request: request)

        if longTask, effectiveConfig.effectiveActiveJobAckEnabled {
            try? await replySink.sendReply(recipient: batch.handleId, service: batch.service, text: effectiveConfig.effectiveActiveJobAckText)
        }

        activeCodexTask = Task { [weak self] in
            await self?.runActiveCodexJob(jobId: jobId, config: effectiveConfig, request: request, batch: batch)
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
                    try await sendOutgoingReply(response, replySink: replySink, recipient: batch.handleId, service: batch.service, config: config)
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
            state.codexSession.lastCompletedAt = DateCodec.iso(now())
            state.codexSession.lastErrorAt = nil
        } catch let error as CodexBackendFailure {
            if activeJobStatus(jobId: jobId) == "canceling" {
                clearActiveJob(jobId: jobId)
                return
            }
            state.codexSession.lastErrorAt = DateCodec.iso(now())
            updateActiveJob(jobId: jobId) { job in
                job.status = "failed"
                job.lastObservedSummary = error.blockedText ?? error.message
            }
            try? await replySink.sendReply(recipient: batch.handleId, service: batch.service, text: failureText(error))
        } catch {
            if activeJobStatus(jobId: jobId) == "canceling" {
                clearActiveJob(jobId: jobId)
                return
            }
            let detail = String(describing: error)
            state.codexSession.lastErrorAt = DateCodec.iso(now())
            updateActiveJob(jobId: jobId) { job in
                job.status = "failed"
                job.lastObservedSummary = detail
            }
            try? await replySink.sendReply(recipient: batch.handleId, service: batch.service, text: "I hit an error while working on that:\n\(detail)")
        }
        clearActiveJob(jobId: jobId)
    }

    private func invokeCodexWithRecovery(config: BridgeConfig, request: PromptRequest, jobId: String, replySink: ReplySink, recipient: String, service: String) async throws -> String {
        let expired = sessionIsExpired(config: config)
        if expired {
            state.codexSession = CodexSessionState(startedAt: DateCodec.iso(now()), expiresAt: DateCodec.iso(now().addingTimeInterval(Double(config.sessionTtlMs) / 1000)))
        }
        do {
            return try await invokeCodex(config: config, request: request, sessionId: expired ? nil : state.codexSession.sessionId, jobId: jobId, replySink: replySink, recipient: recipient, service: service)
        } catch let error as CodexBackendFailure {
            if error.blockedText != nil || expired || state.codexSession.sessionId == nil {
                throw error
            }
            state.codexSession = CodexSessionState(startedAt: DateCodec.iso(now()), expiresAt: DateCodec.iso(now().addingTimeInterval(Double(config.sessionTtlMs) / 1000)))
            return try await invokeCodex(config: config, request: request, sessionId: nil, jobId: jobId, replySink: replySink, recipient: recipient, service: service)
        }
    }

    private func invokeCodex(config: BridgeConfig, request: PromptRequest, sessionId: String?, jobId: String, replySink: ReplySink, recipient: String, service: String) async throws -> String {
        let result = try await makeCodex(config).invoke(request, sessionId: sessionId) { [weak self] event in
            guard let self else { return }
            self.handleCodexStreamEvent(event, jobId: jobId, config: config, replySink: replySink, recipient: recipient, service: service)
        }
        state.codexSession.sessionId = result.sessionId ?? state.codexSession.sessionId
        if state.codexSession.startedAt == nil { state.codexSession.startedAt = DateCodec.iso(now()) }
        state.codexSession.expiresAt = DateCodec.iso(now().addingTimeInterval(Double(config.sessionTtlMs) / 1000))
        updateActiveJob(jobId: jobId) { job in
            job.codexSessionId = result.sessionId ?? job.codexSessionId
            job.outputPath = result.outputPath
            job.status = "running"
        }
        try stores.state.save(state)
        return result.text
    }

    private func sendOutgoingReply(_ text: String, replySink: ReplySink, recipient: String, service: String, config: BridgeConfig) async throws {
        let safeText = safeUserVisibleText(text)
        let outgoing = prepareOutgoingReply(safeText, config: config)
        if !outgoing.text.isEmpty {
            try await replySink.sendReply(recipient: recipient, service: service, text: outgoing.text)
        }
        for attachment in outgoing.attachments {
            do {
                try await replySink.sendAttachment(recipient: recipient, service: service, filePath: attachment)
            } catch {
                throw StoreError.validation("Could not send attachment \(attachment): \(error)")
            }
        }
        if outgoing.text.isEmpty && outgoing.attachments.isEmpty {
            try await replySink.sendReply(recipient: recipient, service: service, text: safeText)
        }
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
        try? await replySink.sendReply(
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
                try? await replySink.sendReply(recipient: recipient, service: service, text: "The permission broker handled a macOS prompt. I’m retrying the job now.")
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
            state.codexSession.sessionId = sessionId
            try? stores.state.save(state)
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
            try? await replySink.sendReply(recipient: recipient, service: service, text: message)
        }
    }

    private func shouldSendProgress(jobId: String, config: BridgeConfig, immediate: Bool) -> Bool {
        immediate
    }

    private func shouldSendMilestone(jobId: String, config: BridgeConfig) -> Bool {
        false
    }

    private func updateActiveJob(jobId: String, _ update: (inout ActiveJob) -> Void) {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard var job = state.activeJob, job.jobId == jobId else { return }
        update(&job)
        state.activeJob = job
        try? stores.state.save(state)
    }

    private func activeJobStatus(jobId: String) -> String? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard state.activeJob?.jobId == jobId else { return nil }
        return state.activeJob?.status
    }

    private func clearActiveJob(jobId: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard state.activeJob?.jobId == jobId else { return }
        state.activeJob = nil
        activeCodexTask = nil
        try? stores.state.save(state)
    }

    private func cancelActiveJob() -> String {
        guard let job = state.activeJob else { return "No active job is running." }
        state.activeJob?.status = "canceling"
        if let pid = job.codexPid {
            _ = try? ProcessRunner().runSync("/bin/kill", ["-TERM", "\(pid)"])
            return "Canceling the active Codex job."
        }
        activeCodexTask?.cancel()
        state.activeJob = nil
        try? stores.state.save(state)
        return "Canceled the active Codex job."
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
            state.activeJob = nil
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
            try? await makeReplySink(config).sendReply(
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

private enum Job {
    case localCommand(String, MessageItem)
    case promptBatch(PendingBatch)
}

public func bridgeLocalCommandName(_ text: String) -> String? {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if ["/codex status", "/codex open", "/codex history"].contains(normalized) {
        return "/codex"
    }
    let command = normalized.split(separator: " ").first.map(String.init)
    guard let command, command != "/codex", BridgeConstants.localCommands.contains(command) else { return nil }
    return command
}

private func localCommandName(_ text: String) -> String? {
    bridgeLocalCommandName(text)
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
