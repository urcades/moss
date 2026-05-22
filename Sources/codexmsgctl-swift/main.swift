import BridgeCore
import Foundation

@main
struct CodexMsgCtlSwift {
    static func main() async {
        do {
            try await run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("Error: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func usage() {
        print("""
        Usage:
          codexmsgctl-swift install [--probe-computer-use]
          codexmsgctl-swift start
          codexmsgctl-swift stop [--remove-plist]
          codexmsgctl-swift status
          codexmsgctl-swift configure --safety standard|permissive|preserve
          codexmsgctl-swift configure --preserve-safety
          codexmsgctl-swift doctor [--probe-computer-use]
          codexmsgctl-swift gates
          codexmsgctl-swift trusted-gates [--recipient HANDLE] [--service iMessage|SMS]
          codexmsgctl-swift smoke text|attachment|bridge-attach|generated-image|edit-image-check|automation|app-server|app-server-callback|mcp-elicitation-callback|inbound-image-check|outbound-image-check|chrome|browser|computer-use [--recipient HANDLE] [--service iMessage|SMS]
          codexmsgctl-swift broker start|stop|status|doctor|events|dry-run-scan
          codexmsgctl-swift reset
        """)
    }

    private static func configureUsage() {
        print("""
        Usage:
          codexmsgctl-swift configure --safety standard|permissive|preserve
          codexmsgctl-swift configure --preserve-safety

        Safety profiles:
          standard    Restricted outgoing attachments and broker auto-clicking off.
          permissive  Full outgoing attachment access and broad broker auto-clicking on.
          preserve    Create/migrate config without changing existing safety fields.
        """)
    }

    private static func run(_ args: [String]) async throws {
        let command = args.first ?? "help"
        let rest = Array(args.dropFirst())
        let paths = RuntimePaths.current()
        let stores = RuntimeStores(paths: paths)

        switch command {
        case "help", "--help", "-h":
            usage()
        case "install":
            let migration = try Migration(paths: paths).migrateFromExistingRuntime(backup: true)
            let lifecycle = ServiceLifecycle(paths: paths)
            let report = await Doctor(paths: paths).run(includeComputerUseProbe: rest.contains("--probe-computer-use"))
            print(Doctor(paths: paths).format(report))
            print("Migration complete. Last processed row id: \(migration.lastProcessedRowId)")
            if let backupDir = migration.backupDir { print("Backup dir: \(backupDir.path)") }
            try await lifecycle.startHelperLaunchAgent()
            print("Swift helper LaunchAgent installed and started: \(BridgeConstants.helperLaunchAgentLabel)")
        case "start":
            try await ServiceLifecycle(paths: paths).startHelperLaunchAgent()
            print("Swift helper LaunchAgent installed and started: \(BridgeConstants.helperLaunchAgentLabel)")
        case "stop":
            let lifecycle = ServiceLifecycle(paths: paths)
            await lifecycle.stopHelperLaunchAgent(removePlist: rest.contains("--remove-plist"))
            await lifecycle.stopPermissionBrokerLaunchAgent(removePlist: rest.contains("--remove-plist"))
            print("Swift helper and permission broker LaunchAgent stop requested.")
        case "status":
            let state = try stores.state.load()
            let config = try stores.config.load()
            let lifecycle = ServiceLifecycle(paths: paths)
            let helperLoaded = await lifecycle.helperLaunchAgentLoaded()
            let brokerLoaded = await lifecycle.permissionBrokerLaunchAgentLoaded()
            print("Messages Codex Bridge Swift status:")
            print("Swift helper LaunchAgent loaded: \(helperLoaded ? "yes" : "no")")
            print("Permission broker LaunchAgent loaded: \(brokerLoaded ? "yes" : "no")")
            print("Helper LaunchAgent path: \(paths.helperLaunchAgentPath.path)")
            print("Permission broker LaunchAgent path: \(paths.permissionBrokerLaunchAgentPath.path)")
            print("Installed app path: \(paths.installedAppPath.path)")
            print("Installed helper path: \(paths.installedHelperExecutablePath.path)")
            print("Installed permission broker path: \(paths.installedPermissionBrokerExecutablePath.path)")
            print("Running bundle version: \(bundleShortVersion(at: Bundle.main.bundleURL) ?? "unknown")")
            print("Installed app version: \(bundleShortVersion(at: paths.installedAppPath) ?? "unknown")")
            print("Installed helper version: \(bundleShortVersion(at: installedHelperBundlePath(paths: paths)) ?? "unknown")")
            print("Installed permission broker version: \(bundleShortVersion(at: installedPermissionBrokerBundlePath(paths: paths)) ?? "unknown")")
            print("Installed app signing: \(codeSigningSummary(at: paths.installedAppPath))")
            print("Installed helper signing: \(codeSigningSummary(at: installedHelperBundlePath(paths: paths)))")
            print("Installed permission broker signing: \(codeSigningSummary(at: installedPermissionBrokerBundlePath(paths: paths)))")
            print("Config path: \(paths.configPath.path)")
            print("State path: \(paths.statePath.path)")
            print("Allowed sender: \(config.allowedSender)")
            print("Trusted senders: \(config.effectiveTrustedSenders.isEmpty ? "none" : config.effectiveTrustedSenders.joined(separator: ", "))")
            print("Codex command: \(config.codex.command)")
            print("Codex cwd: \(config.codex.cwd)")
            print("Last processed row id: \(state.lastProcessedRowId)")
            print("Last processed guid: \(state.lastProcessedGuid ?? "none")")
            print("Pending batch: \(state.pendingBatch.map { "\($0.items.count) item(s)" } ?? "none")")
            print("Active job: \(state.activeJob?.promptPreview ?? "none")")
            print("Active job status: \(state.activeJob?.status ?? "none")")
            print("Active job latest progress: \(state.activeJob?.lastObservedSummary ?? "none")")
            print("Active job Codex thread id: \(state.activeJob?.codexSessionId ?? "none")")
            print("Active job Codex turn id: \(state.activeJob?.codexTurnId ?? "none")")
            print("Last outbound send: \(outboundSendStatusText(state.lastOutboundSend))")
            print("Recent media refs: \(recentMediaRefsStatusText(state.recentMediaRefs ?? []))")
            print("Live smoke results: \(liveSmokeResultsStatusText(state.liveSmokeResults ?? []))")
            print("Bridge smoke automations: \(bridgeSmokeAutomationStatusText(activeBridgeSmokeAutomations(in: paths.codexAutomationsDir)))")
            print("Automation creation status: \(automationCreationStatusText(state.automationCreationStatus))")
            print("Automation routes: \(automationRoutesStatusText(state.automationRoutes ?? []))")
            do {
                let failures = try await recentFailedOutboundEvidence(config: config, limit: 3)
                print("Recent failed outbound evidence: \(formatRecentFailedOutboundEvidence(failures))")
            } catch {
                print("Recent failed outbound evidence: unavailable (\(error))")
            }
            if let brokerStatus = readPermissionBrokerStatus(paths: paths) {
                print("Permission broker accessibility trusted: \(brokerStatus.accessibilityTrusted ? "yes" : "no")")
                print("Permission broker last update: \(brokerStatus.lastSummary ?? "none")")
            } else {
                print("Permission broker status: none")
            }
            print("Codex session id: \(state.codexSession.sessionId ?? "none")")
            if let threadId = state.codexSession.sessionId, !threadId.isEmpty {
                print("Codex thread link: \(codexThreadDeepLink(threadId))")
            }
            print("Codex session expires at: \(state.codexSession.expiresAt ?? "none")")
            if let snapshot = await cachedCodexCapabilitiesBestEffort(command: config.codex.command, paths: paths, ttlMs: Int.max, refreshTimeoutMs: 5_000) {
                print(formatCodexCapabilityCacheLine(snapshot))
                print(formatCodexCapabilityLines(snapshot.capabilities).joined(separator: "\n"))
            } else {
                print("Codex capability cache: unavailable or timed out")
            }
        case "configure":
            try configure(rest, paths: paths, stores: stores)
        case "doctor":
            let report = await Doctor(paths: paths).run(includeComputerUseProbe: rest.contains("--probe-computer-use"))
            print(Doctor(paths: paths).format(report))
            if !report.ok { Foundation.exit(1) }
        case "gates":
            let config = try stores.config.load()
            let state = try stores.state.load()
            let context = BridgeGateChecklistContext(
                allowedSender: config.allowedSender,
                service: smokeOption("--service", in: rest) ?? "iMessage",
                hasActiveJob: state.activeJob != nil,
                hasPendingInteractiveCallback: state.pendingInteractiveCallback != nil,
                hasRecentInboundImage: hasUsableRecentMedia(direction: "inbound", recipient: config.allowedSender, service: smokeOption("--service", in: rest) ?? "iMessage", state: state),
                hasRecentOutboundImage: hasUsableRecentMedia(direction: "outbound", recipient: config.allowedSender, service: smokeOption("--service", in: rest) ?? "iMessage", state: state),
                liveSmokeResults: state.liveSmokeResults ?? []
            )
            print(bridgeGateChecklistText(context: context))
        case "trusted-gates":
            let config = try stores.config.load()
            let recipient = smokeOption("--recipient", in: rest) ?? config.allowedSender
            let service = smokeOption("--service", in: rest) ?? "iMessage"
            let evidence = try await trustedGateEvidence(config: config, recipient: recipient, service: service)
            print(formatTrustedGateEvidence(evidence))
        case "smoke":
            try await runSmokeCommand(rest, paths: paths, stores: stores)
        case "reset":
            var state = try stores.state.load()
            if state.activeJob != nil {
                throw StoreError.validation("Cannot reset while Codex is actively processing a prompt.")
            }
            state.codexSession = CodexSessionState()
            try stores.state.save(state)
            print("Reset Codex session. The next prompt will start fresh.")
        case "broker":
            try await runBrokerCommand(rest, paths: paths)
        default:
            throw StoreError.validation("Unknown command: \(command)")
        }
    }

    private static func runSmokeCommand(_ args: [String], paths: RuntimePaths, stores: RuntimeStores) async throws {
        let subcommand = args.first ?? "help"
        if subcommand == "help" || subcommand == "--help" || subcommand == "-h" {
            print("Usage: codexmsgctl-swift smoke text|attachment|bridge-attach|generated-image|edit-image-check|automation|app-server|app-server-callback|mcp-elicitation-callback|inbound-image-check|outbound-image-check|chrome|browser|computer-use [--recipient HANDLE] [--service iMessage|SMS]")
            return
        }
        let config = try stores.config.load()
        let recipient = smokeOption("--recipient", in: args) ?? config.allowedSender
        let service = smokeOption("--service", in: args) ?? "iMessage"
        guard !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StoreError.validation("Smoke requires --recipient or a configured allowedSender.")
        }
        switch subcommand {
        case "text":
            try await runTextSmoke(recipient: recipient, service: service, config: config)
        case "attachment":
            try await runAttachmentSmoke(recipient: recipient, service: service, config: config, paths: paths)
        case "bridge-attach":
            try await runBridgeAttachSmoke(recipient: recipient, service: service, config: config, paths: paths)
        case "generated-image":
            try await runGeneratedImageSmoke(recipient: recipient, service: service, config: config, paths: paths, stores: stores)
        case "edit-image-check":
            try await runEditImageCheckSmoke(recipient: recipient, service: service, config: config, paths: paths, stores: stores)
        case "automation":
            try runAutomationSmoke(recipient: recipient, service: service, config: config, paths: paths, stores: stores)
        case "app-server":
            try await runAppServerFinalAnswerSmoke(config: config, paths: paths, stores: stores)
        case "app-server-callback":
            try await runAppServerCallbackSmoke(config: config, paths: paths, stores: stores, elicitation: false)
        case "mcp-elicitation-callback":
            try await runAppServerCallbackSmoke(config: config, paths: paths, stores: stores, elicitation: true)
        case "inbound-image-check":
            try await runInboundImageCheckSmoke(recipient: recipient, service: service, config: config, paths: paths, stores: stores)
        case "outbound-image-check":
            try await runOutboundImageCheckSmoke(recipient: recipient, service: service, config: config, paths: paths, stores: stores)
        case "chrome", "browser", "computer-use":
            try await runCapabilitySmoke(subcommand, config: config, paths: paths, stores: stores)
        default:
            throw StoreError.validation("Unknown smoke command: \(subcommand)")
        }
    }

    private static func smokeOption(_ name: String, in args: [String]) -> String? {
        guard let index = args.firstIndex(of: name) else { return nil }
        let valueIndex = args.index(after: index)
        guard valueIndex < args.endIndex else { return nil }
        return args[valueIndex]
    }

    private static func hasUsableRecentMedia(direction: String, recipient: String, service: String, state: BridgeState) -> Bool {
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

    private static func runTextSmoke(recipient: String, service: String, config: BridgeConfig) async throws {
        let marker = "CODEXMSGCTL_SMOKE_TEXT_\(UUID().uuidString)"
        let beforeRowId = try await latestOutgoingMessageRowId(config: config)
        print("Smoke text marker: \(marker)")
        print("Recipient: \(recipient) via \(service)")
        print("Messages DB baseline row: \(beforeRowId)")
        let sendError = await smokeSendError {
            let evidence = try await AppleMessagesReplySink(osascriptCommand: config.osascriptCommand, chunkSize: config.chunkSize, messagesDbPath: config.messagesDbPath)
                .sendReply(recipient: recipient, service: service, text: marker)
            print("Send result: \(outboundDeliveryEvidenceText(evidence))")
        }
        if let sendError {
            print("Send result: FAIL \(sendError)")
        }
        let matched = try await waitForSmokeEvidence {
            try await outboundSmokeTextEvidence(marker: marker, afterRowId: beforeRowId, config: config)
        }
        printSmokeEvidence(matched)
        if let sendError {
            throw StoreError.validation("Smoke text send failed before DB evidence could pass: \(sendError)")
        }
        guard let matched, matched.dbError == 0 else {
            throw StoreError.validation("Smoke text failed: marker was not found in a successful outgoing Messages DB row.")
        }
        print("Smoke text passed.")
    }

    private static func runAttachmentSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths) async throws {
        let marker = "CODEXMSGCTL_SMOKE_ATTACHMENT_\(UUID().uuidString)"
        try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
        let attachment = paths.tmpDir.appendingPathComponent("codexmsgctl-smoke-\(marker).png")
        try bridgeSmokePNGData().write(to: attachment)
        let beforeRowId = try await latestOutgoingMessageRowId(config: config)
        print("Smoke attachment marker: \(marker)")
        print("Attachment path: \(attachment.path)")
        print("Recipient: \(recipient) via \(service)")
        print("Messages DB baseline row: \(beforeRowId)")
        let sendError = await smokeSendError {
            let evidence = try await AppleMessagesReplySink(osascriptCommand: config.osascriptCommand, chunkSize: config.chunkSize, messagesDbPath: config.messagesDbPath)
                .sendAttachment(recipient: recipient, service: service, filePath: attachment.path)
            print("Send result: \(outboundDeliveryEvidenceText(evidence))")
        }
        if let sendError {
            print("Send result: FAIL \(sendError)")
        }
        let matched = try await waitForSmokeEvidence {
            try await outboundSmokeAttachmentEvidence(marker: marker, afterRowId: beforeRowId, config: config)
        }
        printSmokeEvidence(matched)
        if let sendError {
            throw StoreError.validation("Smoke attachment send failed before DB evidence could pass: \(sendError)")
        }
        guard let matched, matched.dbError == 0, matched.transferState != 6 else {
            throw StoreError.validation("Smoke attachment failed: marker was not found in a successful outgoing attachment DB row.")
        }
        print("Smoke attachment passed.")
    }

    private static func runBridgeAttachSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths) async throws {
        let marker = "CODEXMSGCTL_SMOKE_BRIDGE_ATTACH_\(UUID().uuidString)"
        try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
        let attachment = paths.tmpDir.appendingPathComponent("codexmsgctl-smoke-\(marker).png")
        try bridgeSmokePNGData().write(to: attachment)
        let finalReply = "\(marker) generated image ready.\nBRIDGE_ATTACH: \(attachment.path)"
        let outgoing = prepareOutgoingReply(finalReply, config: config)
        guard outgoing.attachments == [attachment.path] else {
            throw StoreError.validation("Smoke bridge-attach failed: BRIDGE_ATTACH directive was not parsed into the expected attachment.")
        }
        let beforeRowId = try await latestOutgoingMessageRowId(config: config)
        print("Smoke bridge-attach marker: \(marker)")
        print("Attachment path: \(attachment.path)")
        print("Recipient: \(recipient) via \(service)")
        print("Messages DB baseline row: \(beforeRowId)")
        let sink = AppleMessagesReplySink(osascriptCommand: config.osascriptCommand, chunkSize: config.chunkSize, messagesDbPath: config.messagesDbPath)
        let attachmentEvidence = try await sink.sendAttachment(recipient: recipient, service: service, filePath: attachment.path)
        print("Attachment send result: \(outboundDeliveryEvidenceText(attachmentEvidence))")
        guard attachmentEvidence.dbError ?? 0 == 0, attachmentEvidence.transferState != 6 else {
            throw StoreError.validation("Smoke bridge-attach failed: attachment delivery did not validate, so success text was not sent.")
        }
        if !outgoing.text.isEmpty {
            let textEvidence = try await sink.sendReply(recipient: recipient, service: service, text: outgoing.text)
            print("Success text send result: \(outboundDeliveryEvidenceText(textEvidence))")
        }
        let matched = try await waitForSmokeEvidence {
            try await outboundSmokeAttachmentEvidence(marker: marker, afterRowId: beforeRowId, config: config)
        }
        printSmokeEvidence(matched)
        guard let matched, matched.dbError == 0, matched.transferState != 6 else {
            throw StoreError.validation("Smoke bridge-attach failed: marker was not found in a successful outgoing attachment DB row.")
        }
        print("Smoke bridge-attach passed.")
    }

    private static func runGeneratedImageSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) async throws {
        let marker = "CODEXMSGCTL_SMOKE_GENERATED_IMAGE_\(UUID().uuidString)"
        try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
        let artifact = paths.tmpDir.appendingPathComponent("codexmsgctl-generated-image-\(marker).png")
        try? FileManager.default.removeItem(at: artifact)
        var smokeConfig = config
        smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
        let beforeRowId = try await latestOutgoingMessageRowId(config: config)
        print("Smoke generated-image marker: \(marker)")
        print("Expected artifact: \(artifact.path)")
        print("Recipient: \(recipient) via \(service)")
        print("Messages DB baseline row: \(beforeRowId)")
        let response = try await invokeAppServerSmoke(
            label: "generated-image",
            marker: marker,
            request: PromptRequest(
                promptText: bridgeGeneratedImageSmokePrompt(marker: marker, artifactPath: artifact.path),
                attachments: []
            ),
            config: smokeConfig,
            paths: paths,
            requireSuccessToken: true
        )
        let outgoing = prepareOutgoingReply(response.text, config: config)
        guard outgoing.attachments == [artifact.path] else {
            throw StoreError.validation("Smoke generated-image failed: app-server response did not include the expected BRIDGE_ATTACH directive for \(artifact.path).")
        }
        guard FileManager.default.fileExists(atPath: artifact.path) else {
            throw StoreError.validation("Smoke generated-image failed: expected artifact was not created at \(artifact.path).")
        }
        let sink = AppleMessagesReplySink(osascriptCommand: config.osascriptCommand, chunkSize: config.chunkSize, messagesDbPath: config.messagesDbPath)
        let attachmentEvidence = try await sink.sendAttachment(recipient: recipient, service: service, filePath: artifact.path)
        print("Attachment send result: \(outboundDeliveryEvidenceText(attachmentEvidence))")
        guard attachmentEvidence.dbError ?? 0 == 0, attachmentEvidence.transferState != 6 else {
            throw StoreError.validation("Smoke generated-image failed: attachment delivery did not validate, so success text was not sent.")
        }
        if !outgoing.text.isEmpty {
            let textEvidence = try await sink.sendReply(recipient: recipient, service: service, text: outgoing.text)
            print("Success text send result: \(outboundDeliveryEvidenceText(textEvidence))")
        }
        let matched = try await waitForSmokeEvidence {
            try await outboundSmokeAttachmentEvidence(marker: marker, afterRowId: beforeRowId, config: config)
        }
        printSmokeEvidence(matched)
        guard let matched, matched.dbError == 0, matched.transferState != 6 else {
            throw StoreError.validation("Smoke generated-image failed: marker was not found in a successful outgoing attachment DB row.")
        }
        var state = try stores.state.load()
        var refs = state.recentMediaRefs ?? []
        refs.append(RecentMediaRef(
            direction: "outbound",
            rowId: matched.rowId,
            handleId: recipient,
            service: service,
            path: artifact.path,
            transferName: artifact.lastPathComponent,
            kind: "image",
            createdAt: DateCodec.iso(Date()),
            exists: FileManager.default.fileExists(atPath: artifact.path)
        ))
        state.recentMediaRefs = Array(refs.suffix(30))
        try stores.state.save(state)
        print("Generated image row: \(matched.rowId)")
        print("Generated image path: \(artifact.path)")
        print("Smoke generated-image passed.")
    }

    private static func runEditImageCheckSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) async throws {
        let marker = "CODEXMSGCTL_SMOKE_EDIT_IMAGE_\(UUID().uuidString)"
        try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
        let artifact = paths.tmpDir.appendingPathComponent("codexmsgctl-edited-image-\(marker).png")
        try? FileManager.default.removeItem(at: artifact)
        var smokeConfig = config
        smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
        let state = try stores.state.load()
        let smoke = try buildImageEditSmokeRequest(
            recipient: recipient,
            service: service,
            recentMediaRefs: state.recentMediaRefs ?? [],
            artifactPath: artifact.path,
            marker: marker
        )
        let beforeRowId = try await latestOutgoingMessageRowId(config: config)
        print("Smoke edit-image-check marker: \(marker)")
        print("Source image row: \(smoke.mediaRef.rowId.map(String.init) ?? "none")")
        print("Source image path: \(smoke.mediaRef.path)")
        print("Expected artifact: \(artifact.path)")
        print("Recipient: \(recipient) via \(service)")
        print("Messages DB baseline row: \(beforeRowId)")
        let response = try await invokeAppServerSmoke(
            label: "edit-image-check",
            marker: marker,
            request: smoke.request,
            config: smokeConfig,
            paths: paths,
            requireSuccessToken: true
        )
        let outgoing = prepareOutgoingReply(response.text, config: config)
        guard outgoing.attachments == [artifact.path] else {
            throw StoreError.validation("Smoke edit-image-check failed: app-server response did not include the expected BRIDGE_ATTACH directive for \(artifact.path).")
        }
        guard FileManager.default.fileExists(atPath: artifact.path) else {
            throw StoreError.validation("Smoke edit-image-check failed: expected edited artifact was not created at \(artifact.path).")
        }
        let sink = AppleMessagesReplySink(osascriptCommand: config.osascriptCommand, chunkSize: config.chunkSize, messagesDbPath: config.messagesDbPath)
        let attachmentEvidence = try await sink.sendAttachment(recipient: recipient, service: service, filePath: artifact.path)
        print("Attachment send result: \(outboundDeliveryEvidenceText(attachmentEvidence))")
        guard attachmentEvidence.dbError ?? 0 == 0, attachmentEvidence.transferState != 6 else {
            throw StoreError.validation("Smoke edit-image-check failed: attachment delivery did not validate, so success text was not sent.")
        }
        if !outgoing.text.isEmpty {
            let textEvidence = try await sink.sendReply(recipient: recipient, service: service, text: outgoing.text)
            print("Success text send result: \(outboundDeliveryEvidenceText(textEvidence))")
        }
        let matched = try await waitForSmokeEvidence {
            try await outboundSmokeAttachmentEvidence(marker: marker, afterRowId: beforeRowId, config: config)
        }
        printSmokeEvidence(matched)
        guard let matched, matched.dbError == 0, matched.transferState != 6 else {
            throw StoreError.validation("Smoke edit-image-check failed: marker was not found in a successful outgoing attachment DB row.")
        }
        var reloaded = try stores.state.load()
        var refs = reloaded.recentMediaRefs ?? []
        refs.append(RecentMediaRef(
            direction: "outbound",
            rowId: matched.rowId,
            handleId: recipient,
            service: service,
            path: artifact.path,
            transferName: artifact.lastPathComponent,
            kind: "image",
            createdAt: DateCodec.iso(Date()),
            exists: FileManager.default.fileExists(atPath: artifact.path)
        ))
        reloaded.recentMediaRefs = Array(refs.suffix(30))
        try stores.state.save(reloaded)
        print("Edited image row: \(matched.rowId)")
        print("Edited image path: \(artifact.path)")
        print("Smoke edit-image-check passed.")
    }

    private static func runAutomationSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) throws {
        let result = try createCodexAutomationSmoke(
            recipient: recipient,
            service: service,
            config: config,
            paths: paths,
            stores: stores
        )
        print("Smoke automation marker: \(result.marker)")
        print("Automation id: \(result.automation.id)")
        print("Automation name: \(result.automation.name)")
        print("Automation file: \(result.automation.path)")
        print("Schedule: \(result.automation.rrule)")
        print("Route: \(result.route.recipient) via \(result.route.service)")
        print("Smoke automation passed.")
    }

    private static func runAppServerFinalAnswerSmoke(config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) async throws {
        let marker = "CODEXMSGCTL_SMOKE_APP_SERVER_\(UUID().uuidString)"
        var smokeConfig = config
        smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
        let request = PromptRequest(
            promptText: appServerFinalAnswerSmokePrompt(marker: marker),
            attachments: []
        )
        print("Smoke app-server marker: \(marker)")
        do {
            let response = try await invokeAppServerSmoke(label: "app-server", marker: marker, request: request, config: smokeConfig, paths: paths, requireSuccessToken: true)
            try recordLiveSmokeResult(stores: stores, name: "app-server", marker: marker, status: "passed", detail: response.text, threadId: response.sessionId, turnId: nil)
            print("Smoke app-server passed.")
        } catch {
            try? recordLiveSmokeResult(stores: stores, name: "app-server", marker: marker, status: "failed", detail: String(describing: error), threadId: nil, turnId: nil)
            throw error
        }
    }

    private static func runAppServerCallbackSmoke(config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores, elicitation: Bool) async throws {
        let label = elicitation ? "mcp-elicitation-callback" : "app-server-callback"
        let markerPrefix = elicitation ? "CODEXMSGCTL_SMOKE_MCP_ELICITATION_CALLBACK" : "CODEXMSGCTL_SMOKE_APP_SERVER_CALLBACK"
        let marker = "\(markerPrefix)_\(UUID().uuidString)"
        let answer = "cli-callback-answer-\(UUID().uuidString.prefix(8))"
        var smokeConfig = config
        smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
        let callbackRecords = AppServerCallbackSmokeRecords()
        let responder: CodexInteractiveCallbackResponder = { method, requestId, params in
            callbackRecords.append(method: method, requestId: "\(requestId)", prompt: callbackPromptSummary(params: params), answer: answer)
            return appServerCallbackSmokeResponse(method: method, params: params, answer: answer)
        }
        let request = PromptRequest(
            promptText: elicitation ? bridgeAppServerMcpElicitationSmokePrompt(marker: marker) : bridgeAppServerCallbackSmokePrompt(marker: marker),
            attachments: []
        )
        print("Smoke \(label) marker: \(marker)")
        print("Callback answer: \(answer)")
        let response = try await invokeAppServerSmoke(
            label: label,
            marker: marker,
            request: request,
            config: smokeConfig,
            paths: paths,
            requireSuccessToken: false,
            interactiveCallbackResponder: responder
        )
        let records = callbackRecords.snapshot()
        for record in records {
            print("Callback request: method=\(record.method) id=\(record.requestId) prompt=\"\(record.prompt)\" answer=\"\(record.answer)\"")
        }
        guard !records.isEmpty else {
            let detail = computerUseProbeDetailWithWindowDiagnostics(response.text)
            try recordLiveSmokeResult(stores: stores, name: label, marker: marker, status: "blocked", detail: detail, threadId: response.sessionId, turnId: nil)
            throw StoreError.validation("Smoke \(label) failed: app-server completed without invoking an interactive callback. Response: \(detail)")
        }
        guard response.text.localizedCaseInsensitiveContains("SUCCESS") else {
            let detail = computerUseProbeDetailWithWindowDiagnostics(response.text)
            try recordLiveSmokeResult(stores: stores, name: label, marker: marker, status: "failed", detail: detail, threadId: response.sessionId, turnId: nil)
            throw StoreError.validation("Smoke \(label) failed: callback was handled but final answer did not report SUCCESS. Response: \(detail)")
        }
        guard response.text.contains(answer) else {
            let detail = "Final answer did not echo callback answer \(answer). Response: \(computerUseProbeDetailWithWindowDiagnostics(response.text))"
            try recordLiveSmokeResult(stores: stores, name: label, marker: marker, status: "failed", detail: detail, threadId: response.sessionId, turnId: nil)
            throw StoreError.validation("Smoke \(label) failed: final answer did not echo callback answer \(answer).")
        }
        try recordLiveSmokeResult(stores: stores, name: label, marker: marker, status: "passed", detail: response.text, threadId: response.sessionId, turnId: nil)
        print("Smoke \(label) passed.")
    }

    private static func runInboundImageCheckSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) async throws {
        var state = try stores.state.load()
        var refs = state.recentMediaRefs ?? []
        if (try? buildInboundImageSmokeRequest(recipient: recipient, service: service, recentMediaRefs: refs)) == nil,
           let recovered = try await latestTrustedInboundImageMediaRef(config: config, recipient: recipient, service: service) {
            refs.append(recovered)
            state.recentMediaRefs = Array(refs.suffix(30))
            try stores.state.save(state)
            print("Recovered inbound image from Messages DB row: \(recovered.rowId.map(String.init) ?? "none")")
        }
        let smoke = try buildInboundImageSmokeRequest(recipient: recipient, service: service, recentMediaRefs: refs)
        print("Smoke inbound-image-check marker: \(smoke.marker)")
        print("Inbound image row: \(smoke.mediaRef.rowId.map(String.init) ?? "none")")
        print("Inbound image path: \(smoke.mediaRef.path)")
        print("Inbound image transfer name: \(smoke.mediaRef.transferName ?? "unknown")")
        try await runAppServerMarkerSmoke(
            label: "inbound-image-check",
            marker: smoke.marker,
            request: smoke.request,
            config: config,
            paths: paths,
            requireSuccessToken: true
        )
    }

    private static func runOutboundImageCheckSmoke(recipient: String, service: String, config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) async throws {
        let marker = "CODEXMSGCTL_SMOKE_OUTBOUND_IMAGE_\(UUID().uuidString)"
        try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
        let attachment = paths.tmpDir.appendingPathComponent("codexmsgctl-smoke-\(marker).png")
        try bridgeSmokePNGData().write(to: attachment)
        let beforeRowId = try await latestOutgoingMessageRowId(config: config)
        print("Smoke outbound-image-check marker: \(marker)")
        print("Attachment path: \(attachment.path)")
        print("Recipient: \(recipient) via \(service)")
        print("Messages DB baseline row: \(beforeRowId)")
        let evidence = try await AppleMessagesReplySink(osascriptCommand: config.osascriptCommand, chunkSize: config.chunkSize, messagesDbPath: config.messagesDbPath)
            .sendAttachment(recipient: recipient, service: service, filePath: attachment.path)
        print("Send result: \(outboundDeliveryEvidenceText(evidence))")
        let matched = try await waitForSmokeEvidence {
            try await outboundSmokeAttachmentEvidence(marker: marker, afterRowId: beforeRowId, config: config)
        }
        printSmokeEvidence(matched)
        guard let matched, matched.dbError == 0, matched.transferState != 6 else {
            throw StoreError.validation("Smoke outbound-image-check failed: marker was not found in a successful outgoing attachment DB row.")
        }
        var state = try stores.state.load()
        var refs = state.recentMediaRefs ?? []
        refs.append(RecentMediaRef(
            direction: "outbound",
            rowId: matched.rowId,
            handleId: recipient,
            service: service,
            path: attachment.path,
            transferName: attachment.lastPathComponent,
            kind: "image",
            createdAt: DateCodec.iso(Date()),
            exists: FileManager.default.fileExists(atPath: attachment.path)
        ))
        state.recentMediaRefs = Array(refs.suffix(30))
        try stores.state.save(state)
        let smoke = try buildOutboundImageSmokeRequest(recipient: recipient, service: service, recentMediaRefs: state.recentMediaRefs ?? [], marker: marker)
        print("Outbound image row: \(matched.rowId)")
        print("Outbound image path: \(smoke.mediaRef.path)")
        try await runAppServerMarkerSmoke(
            label: "outbound-image-check",
            marker: smoke.marker,
            request: smoke.request,
            config: config,
            paths: paths,
            requireSuccessToken: true
        )
    }

    private static func runCapabilitySmoke(_ capability: String, config: BridgeConfig, paths: RuntimePaths, stores: RuntimeStores) async throws {
        let marker = "CODEXMSGCTL_SMOKE_\(capability.replacingOccurrences(of: "-", with: "_").uppercased())_\(UUID().uuidString)"
        var smokeConfig = config
        smokeConfig.timeoutMs = min(config.timeoutMs, 60_000)
        let request = PromptRequest(promptText: bridgeCapabilitySmokePrompt(capability: capability, marker: marker), attachments: [])
        print("Smoke \(capability) marker: \(marker)")
        do {
            let response = try await invokeAppServerSmoke(label: capability, marker: marker, request: request, config: smokeConfig, paths: paths)
            let responseText = computerUseProbeDetailWithWindowDiagnostics(response.text)
            let status = liveSmokeStatus(from: responseText)
            try recordLiveSmokeResult(stores: stores, name: capability, marker: marker, status: status, detail: responseText, threadId: response.sessionId, turnId: nil)
            print("Smoke \(capability) passed.")
        } catch {
            try? recordLiveSmokeResult(stores: stores, name: capability, marker: marker, status: "failed", detail: String(describing: error), threadId: nil, turnId: nil)
            throw error
        }
    }

    private static func runAppServerMarkerSmoke(label: String, marker: String, request: PromptRequest, config: BridgeConfig, paths: RuntimePaths, requireSuccessToken: Bool = false) async throws {
        _ = try await invokeAppServerSmoke(label: label, marker: marker, request: request, config: config, paths: paths, requireSuccessToken: requireSuccessToken)
        print("Smoke \(label) passed.")
    }

    private static func invokeAppServerSmoke(label: String, marker: String, request: PromptRequest, config: BridgeConfig, paths: RuntimePaths, requireSuccessToken: Bool = false, interactiveCallbackResponder: CodexInteractiveCallbackResponder? = nil) async throws -> CodexResponse {
        let events = CapabilitySmokeEvents()
        do {
            let response = try await CodexAppServerBackend(config: config, paths: paths, interactiveCallbackResponder: interactiveCallbackResponder).invoke(request, sessionId: nil) { event in
                switch event {
                case .processStarted(let pid):
                    events.setProcessPid(pid)
                    print("App-server pid: \(pid)")
                case .sessionStarted(let id):
                    events.setThreadId(id)
                    print("Thread id: \(id)")
                case .turnStarted(let id):
                    events.setTurnId(id)
                    print("Turn id: \(id)")
                case .progress(let text), .milestone(let text):
                    print("Progress: \(text)")
                case .blocker(let text):
                    print("Blocker: \(text)")
                case .question(let text):
                    print("Question: \(text)")
                }
            }
            if let processPid = events.processPid() {
                _ = terminateProcessTree(rootPid: processPid)
            }
            let responseText = computerUseProbeDetailWithWindowDiagnostics(response.text)
            print("Response: \(responseText)")
            print("Thread id: \(response.sessionId ?? events.threadId() ?? "none")")
            print("Turn id: \(events.turnId() ?? "none")")
            guard responseText.contains(marker) else {
                throw StoreError.validation("Smoke \(label) failed: response did not contain marker \(marker).")
            }
            if requireSuccessToken, !responseText.localizedCaseInsensitiveContains("SUCCESS") {
                throw StoreError.validation("Smoke \(label) failed: response contained marker but did not report SUCCESS. Response: \(responseText)")
            }
            return response
        } catch let error as CodexBackendFailure {
            if let processPid = events.processPid() {
                _ = terminateProcessTree(rootPid: processPid)
            }
            let detail = computerUseProbeDetailWithWindowDiagnostics(error.blockedText ?? error.message)
            print("Smoke \(label) blocker/failure: \(detail)")
            throw StoreError.validation("Smoke \(label) failed: \(detail)")
        } catch {
            if let processPid = events.processPid() {
                _ = terminateProcessTree(rootPid: processPid)
            }
            throw error
        }
    }

    private static func appServerFinalAnswerSmokePrompt(marker: String) -> String {
        "Reply only with \(marker) SUCCESS. Do not call tools, plugins, apps, browser, or Computer Use."
    }

    private static func smokeSendError(_ send: () async throws -> Void) async -> Error? {
        do {
            try await send()
            return nil
        } catch {
            return error
        }
    }

    private static func waitForSmokeEvidence(_ probe: () async throws -> OutboundSmokeEvidence?) async throws -> OutboundSmokeEvidence? {
        var last: OutboundSmokeEvidence?
        for attempt in 1...10 {
            last = try await probe()
            if last != nil { return last }
            if attempt < 10 {
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        return last
    }

    private static func printSmokeEvidence(_ evidence: OutboundSmokeEvidence?) {
        guard let evidence else {
            print("DB evidence: FAIL marker not found")
            return
        }
        print("DB evidence: row \(evidence.rowId), guid \(evidence.guid ?? "unknown"), error \(evidence.dbError), date_delivered \(evidence.dateDelivered)")
        if let transferState = evidence.transferState {
            print("Attachment transfer_state: \(transferState)")
        }
        if let attachmentName = evidence.attachmentName {
            print("Attachment name: \(attachmentName)")
        }
    }

    private static func outboundDeliveryEvidenceText(_ evidence: OutboundDeliveryEvidence) -> String {
        var parts = [evidence.transport]
        if let rowId = evidence.dbRowId {
            parts.append("row \(rowId)")
        }
        if let dbError = evidence.dbError {
            parts.append("error \(dbError)")
        }
        if let transferState = evidence.transferState {
            parts.append("transfer_state \(transferState)")
        }
        if let delivered = evidence.dateDelivered {
            parts.append("date_delivered \(delivered)")
        }
        if let detail = evidence.detail {
            parts.append(detail)
        }
        return parts.joined(separator: ", ")
    }

    private static func automationCreationStatusText(_ status: AutomationCreationStatus?) -> String {
        guard let status else { return "none" }
        var parts = [
            status.phase,
            status.name ?? status.automationId ?? "unknown"
        ]
        if let path = status.createdFilePath {
            parts.append(path)
        }
        if let routeStatus = status.routeStatus {
            parts.append(routeStatus)
        }
        if let failureText = status.failureText {
            parts.append("failure \(failureText)")
        }
        return parts.joined(separator: "; ")
    }

    private static func automationRoutesStatusText(_ routes: [CodexAutomationRoute]) -> String {
        guard !routes.isEmpty else { return "none" }
        let latest = routes.sorted { $0.createdAt < $1.createdAt }.suffix(3)
        let details = latest.map { route in
            "\(route.name) (\(route.automationId)) -> \(route.recipient) via \(route.service)"
        }.joined(separator: " | ")
        return "\(routes.count) route(s); latest: \(details)"
    }

    private static func configure(_ args: [String], paths: RuntimePaths, stores: RuntimeStores) throws {
        if args.contains("--help") || args.contains("-h") {
            configureUsage()
            return
        }
        let profile = try configureSafetyProfile(args)
        try ensureRuntimeDirectories(paths)
        var config = (try? stores.config.load()) ?? defaultBridgeConfig(paths: paths)
        migrateTrustedSenders(&config)
        applySafetyProfile(profile, to: &config)
        try validateConfig(config)
        try stores.config.save(config)
        print("Config updated: \(paths.configPath.path)")
        print("Safety profile: \(profile.rawValue)")
        print("Outgoing attachments: \(config.effectiveOutgoingAttachmentMode), roots: \(config.effectiveOutgoingAttachmentRoots.joined(separator: ", ")), extensions: \(config.effectiveOutgoingAttachmentExtensions.joined(separator: ", "))")
        let broker = config.effectivePermissionBroker
        print("Permission broker auto-clicking: \(broker.enabled ? "on" : "off"), mode: \(broker.mode)")
        print("Trusted senders: \(config.effectiveTrustedSenders.isEmpty ? "none" : config.effectiveTrustedSenders.joined(separator: ", "))")
    }

    private static func configureSafetyProfile(_ args: [String]) throws -> SafetyProfile {
        if args.contains("--preserve-safety") {
            return .preserve
        }
        if let index = args.firstIndex(of: "--safety") {
            let valueIndex = args.index(after: index)
            guard valueIndex < args.endIndex else {
                throw StoreError.validation("--safety requires standard, permissive, or preserve.")
            }
            guard let profile = SafetyProfile(rawValue: args[valueIndex]) else {
                throw StoreError.validation("Unknown safety profile: \(args[valueIndex])")
            }
            return profile
        }
        return .standard
    }

    private static func runBrokerCommand(_ args: [String], paths: RuntimePaths) async throws {
        let subcommand = args.first ?? "status"
        let lifecycle = ServiceLifecycle(paths: paths)
        switch subcommand {
        case "start":
            try await lifecycle.startPermissionBrokerLaunchAgent()
            print("Permission broker LaunchAgent installed and started: \(BridgeConstants.permissionBrokerLaunchAgentLabel)")
        case "stop":
            await lifecycle.stopPermissionBrokerLaunchAgent(removePlist: args.contains("--remove-plist"))
            print("Permission broker LaunchAgent stop requested.")
        case "status":
            let loaded = await lifecycle.permissionBrokerLaunchAgentLoaded()
            print("Permission broker loaded: \(loaded ? "yes" : "no")")
            print("LaunchAgent path: \(paths.permissionBrokerLaunchAgentPath.path)")
            print("Executable path: \(paths.installedPermissionBrokerExecutablePath.path)")
            if let status = readPermissionBrokerStatus(paths: paths) {
                print("Accessibility trusted: \(status.accessibilityTrusted ? "yes" : "no")")
                print("Mode: \(status.mode)")
                print("Last scan: \(status.lastScanAt ?? "none")")
                print("Last action: \(status.lastActionAt ?? "none")")
                print("Last update: \(status.lastSummary ?? "none")")
            } else {
                print("Status: none")
            }
        case "doctor":
            let report = await Doctor(paths: paths).run()
            let brokerChecks = DoctorReport(ok: report.checks.filter { $0.name.localizedCaseInsensitiveContains("broker") }.allSatisfy(\.ok), checks: report.checks.filter { $0.name.localizedCaseInsensitiveContains("broker") })
            print(Doctor(paths: paths).format(brokerChecks))
            if !brokerChecks.ok { Foundation.exit(1) }
        case "events":
            let limit = Int(args.dropFirst().first ?? "") ?? 20
            let events = recentPermissionBrokerEvents(paths: paths, limit: limit)
            if events.isEmpty {
                print("No permission broker events recorded.")
            } else {
                for event in events {
                    print("\(event.timestamp) \(event.kind) owner=\(event.ownerName) button=\(event.buttonLabel ?? "-") result=\(event.actionResult)")
                }
            }
        case "dry-run-scan":
            let executable = FileManager.default.fileExists(atPath: paths.installedPermissionBrokerExecutablePath.path)
                ? paths.installedPermissionBrokerExecutablePath.path
                : paths.builtPermissionBrokerExecutablePath.path
            _ = try await ProcessRunner().run(executable, ["--dry-run-scan"])
            print("Permission broker dry-run scan complete. Recent events:")
            for event in recentPermissionBrokerEvents(paths: paths, limit: 5) {
                print("\(event.timestamp) \(event.kind) owner=\(event.ownerName) button=\(event.buttonLabel ?? "-") result=\(event.actionResult)")
            }
        default:
            throw StoreError.validation("Unknown broker command: \(subcommand)")
        }
    }
}

private final class CapabilitySmokeEvents: @unchecked Sendable {
    private let lock = NSLock()
    private var pid: Int32?
    private var thread: String?
    private var turn: String?

    func setProcessPid(_ value: Int32) {
        lock.lock()
        pid = value
        lock.unlock()
    }

    func processPid() -> Int32? {
        lock.lock()
        defer { lock.unlock() }
        return pid
    }

    func setThreadId(_ value: String) {
        lock.lock()
        thread = value
        lock.unlock()
    }

    func threadId() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return thread
    }

    func setTurnId(_ value: String) {
        lock.lock()
        turn = value
        lock.unlock()
    }

    func turnId() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return turn
    }
}

private struct AppServerCallbackSmokeRecord: Sendable {
    var method: String
    var requestId: String
    var prompt: String
    var answer: String
}

private final class AppServerCallbackSmokeRecords: @unchecked Sendable {
    private let lock = NSLock()
    private var records: [AppServerCallbackSmokeRecord] = []

    func append(method: String, requestId: String, prompt: String, answer: String) {
        lock.lock()
        records.append(AppServerCallbackSmokeRecord(method: method, requestId: requestId, prompt: prompt, answer: answer))
        lock.unlock()
    }

    func snapshot() -> [AppServerCallbackSmokeRecord] {
        lock.lock()
        defer { lock.unlock() }
        return records
    }
}

private func callbackPromptSummary(params: [String: Any]?) -> String {
    let candidates = [
        params?["prompt"] as? String,
        params?["message"] as? String,
        (params?["request"] as? [String: Any])?["message"] as? String
    ].compactMap { $0 }
    if let candidate = candidates.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
        return callbackSmokeTruncate(cleanPlainText(candidate), limit: 160)
    }
    let questions = params?["questions"] as? [[String: Any]] ?? []
    let questionText = questions.compactMap { question -> String? in
        let id = question["id"] as? String
        let header = question["header"] as? String
        let body = question["question"] as? String ?? question["prompt"] as? String
        return [id, header, body]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ": ")
    }.joined(separator: " | ")
    if !questionText.isEmpty {
        return callbackSmokeTruncate(cleanPlainText(questionText), limit: 160)
    }
    return callbackSmokeTruncate(cleanPlainText(searchableText(params ?? [:])), limit: 160)
}

private func callbackSmokeTruncate(_ value: String, limit: Int) -> String {
    guard value.count > limit else { return value }
    let index = value.index(value.startIndex, offsetBy: limit)
    return String(value[..<index])
}
