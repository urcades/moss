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
          codexmsgctl-swift smoke text|attachment [--recipient HANDLE] [--service iMessage|SMS]
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
            let snapshot = await cachedCodexCapabilities(command: config.codex.command, paths: paths)
            print(formatCodexCapabilityCacheLine(snapshot))
            print(formatCodexCapabilityLines(snapshot.capabilities).joined(separator: "\n"))
        case "configure":
            try configure(rest, paths: paths, stores: stores)
        case "doctor":
            let report = await Doctor(paths: paths).run(includeComputerUseProbe: rest.contains("--probe-computer-use"))
            print(Doctor(paths: paths).format(report))
            if !report.ok { Foundation.exit(1) }
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
            print("Usage: codexmsgctl-swift smoke text|attachment [--recipient HANDLE] [--service iMessage|SMS]")
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
        try smokePNGData().write(to: attachment)
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

    private static func smokePNGData() throws -> Data {
        let encoded = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
        guard let data = Data(base64Encoded: encoded) else {
            throw StoreError.validation("Could not decode smoke PNG fixture.")
        }
        return data
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
