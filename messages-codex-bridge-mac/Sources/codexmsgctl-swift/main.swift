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
          codexmsgctl-swift stop
          codexmsgctl-swift status
          codexmsgctl-swift doctor [--probe-computer-use]
          codexmsgctl-swift broker start|stop|status|doctor|events|dry-run-scan
          codexmsgctl-swift reset
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
            print("Config path: \(paths.configPath.path)")
            print("State path: \(paths.statePath.path)")
            print("Allowed sender: \(config.allowedSender)")
            print("Codex command: \(config.codex.command)")
            print("Codex cwd: \(config.codex.cwd)")
            print("Last processed row id: \(state.lastProcessedRowId)")
            print("Last processed guid: \(state.lastProcessedGuid ?? "none")")
            print("Pending batch: \(state.pendingBatch.map { "\($0.items.count) item(s)" } ?? "none")")
            print("Active job: \(state.activeJob?.promptPreview ?? "none")")
            print("Active job status: \(state.activeJob?.status ?? "none")")
            print("Active job latest progress: \(state.activeJob?.lastObservedSummary ?? "none")")
            print("Active job Codex thread id: \(state.activeJob?.codexSessionId ?? "none")")
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
        case "doctor":
            let report = await Doctor(paths: paths).run(includeComputerUseProbe: rest.contains("--probe-computer-use"))
            print(Doctor(paths: paths).format(report))
            if !report.ok { Foundation.exit(1) }
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
