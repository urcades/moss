import Foundation

public struct DoctorCheck: Equatable, Sendable {
    public var name: String
    public var ok: Bool
    public var detail: String

    public init(name: String, ok: Bool, detail: String) {
        self.name = name
        self.ok = ok
        self.detail = detail
    }
}

public struct DoctorReport: Equatable, Sendable {
    public var ok: Bool
    public var checks: [DoctorCheck]

    public init(ok: Bool, checks: [DoctorCheck]) {
        self.ok = ok
        self.checks = checks
    }
}

public final class Doctor: @unchecked Sendable {
    private let paths: RuntimePaths
    private let runner: ProcessRunner

    public init(paths: RuntimePaths = .current(), runner: ProcessRunner = ProcessRunner()) {
        self.paths = paths
        self.runner = runner
    }

    public func run(includeComputerUseProbe: Bool = false) async -> DoctorReport {
        let stores = RuntimeStores(paths: paths)
        let config = (try? stores.config.load()) ?? defaultBridgeConfig(paths: paths)
        var checks: [DoctorCheck] = []
        checks.append(contentsOf: runtimeDiagnosticChecks(paths: paths))
        checks.append(checkCodex(config))
        checks.append(contentsOf: await checkCodexCapabilities(config))
        checks.append(checkTrustedSenders(config))
        checks.append(checkMessagesDb(config))
        checks.append(await checkMessagesAutomation(config))
        checks.append(checkTCC("Full Disk Access", services: ["kTCCServiceSystemPolicyAllFiles"], clients: bridgeClients(), missingDetail: "Grant Full Disk Access to Messages Codex Bridge so it can read Messages DB."))
        checks.append(checkTCC("Codex Accessibility", services: ["kTCCServiceAccessibility"], clients: codexComputerUseClients(), missingDetail: "Grant Accessibility to Codex and Codex Computer Use."))
        checks.append(checkTCC("Codex Screen Recording", services: ["kTCCServiceScreenCapture"], clients: codexComputerUseClients(), missingDetail: "Grant Screen Recording to Codex and Codex Computer Use."))
        checks.append(checkAppleEventsTarget("Automation: Computer Use", target: "com.openai.sky.CUAService"))
        checks.append(await checkPermissionBrokerLaunchAgent())
        checks.append(checkTCC("Permission Broker Accessibility", services: ["kTCCServiceAccessibility"], clients: permissionBrokerClients(), missingDetail: "Grant Accessibility to Messages Codex Permission Broker so it can handle visible permission prompts."))
        checks.append(checkPermissionBrokerStatus())
        if includeComputerUseProbe {
            checks.append(await computerUseProbe(config))
        }
        return DoctorReport(ok: checks.allSatisfy(\.ok), checks: checks)
    }

    public func format(_ report: DoctorReport) -> String {
        var lines = [report.ok ? "Doctor passed." : "Doctor found issues."]
        lines += report.checks.map { "\($0.ok ? "OK" : "FAIL")  \($0.name): \($0.detail)" }
        return lines.joined(separator: "\n")
    }

    private func checkCodex(_ config: BridgeConfig) -> DoctorCheck {
        FileManager.default.isExecutableFile(atPath: config.codex.command)
            ? DoctorCheck(name: "Codex CLI available", ok: true, detail: config.codex.command)
            : DoctorCheck(name: "Codex CLI available", ok: false, detail: "Unable to execute \(config.codex.command). Install Codex.app or update config.json to the bundled Codex CLI path.")
    }

    private func checkCodexCapabilities(_ config: BridgeConfig) async -> [DoctorCheck] {
        let snapshot = await cachedCodexCapabilities(command: config.codex.command, runner: runner, paths: paths)
        let capabilities = snapshot.capabilities
        var checks = [
            DoctorCheck(name: "Codex capability cache", ok: true, detail: snapshot.refreshed ? "refreshed at \(snapshot.cachedAt)" : "cached at \(snapshot.cachedAt), age \(snapshot.cacheAgeSeconds ?? 0)s"),
            DoctorCheck(name: "Codex version", ok: true, detail: capabilities.version ?? "unknown"),
            DoctorCheck(name: "Codex app-server", ok: true, detail: capabilities.appServerAvailable ? "yes" : "no"),
            DoctorCheck(name: "Codex remote-control", ok: true, detail: capabilities.remoteControlAvailable ? "yes" : "no"),
            DoctorCheck(name: "Codex thread/read", ok: true, detail: capabilities.threadReadAvailable ? "yes" : "no"),
            DoctorCheck(name: "Codex enhanced bridge UX", ok: true, detail: capabilities.enhancedBridgeUXAvailable ? "yes" : "degraded")
        ]
        checks += capabilities.warnings.map { DoctorCheck(name: "Codex capability warning", ok: true, detail: $0) }
        return checks
    }

    private func checkTrustedSenders(_ config: BridgeConfig) -> DoctorCheck {
        let senders = config.effectiveTrustedSenders
        guard !senders.isEmpty else {
            return DoctorCheck(name: "Trusted senders configured", ok: false, detail: "No trusted senders configured.")
        }
        return DoctorCheck(name: "Trusted senders configured", ok: true, detail: "\(senders.count) sender(s)")
    }

    private func checkMessagesDb(_ config: BridgeConfig) -> DoctorCheck {
        if FileManager.default.isReadableFile(atPath: config.messagesDbPath) {
            return DoctorCheck(name: "Messages database readable", ok: true, detail: config.messagesDbPath)
        }
        return DoctorCheck(
            name: "Messages database readable",
            ok: false,
            detail: "macOS Full Disk Access is likely blocking Messages DB reads. Grant Full Disk Access to Messages Codex Bridge and its helper."
        )
    }

    private func checkMessagesAutomation(_ config: BridgeConfig) async -> DoctorCheck {
        let script = #"tell application "Messages" to get id of 1st service whose service type = iMessage"#
        do {
            let result = try await runner.run(config.osascriptCommand, ["-e", script])
            return DoctorCheck(name: "Messages automation reachable", ok: true, detail: result.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return DoctorCheck(name: "Messages automation reachable", ok: false, detail: "macOS Automation is likely blocking Messages access. Open Automation Settings from the menu, then allow Messages access for Messages Codex Bridge. Detail: \(error)")
        }
    }

    private func bridgeClients() -> [String] {
        [
            BridgeConstants.appBundleIdentifier,
            BridgeConstants.helperBundleIdentifier,
            Bundle.main.bundleIdentifier,
            CommandLine.arguments.first
        ].compactMap { $0 }
    }

    private func codexComputerUseClients() -> [String] {
        [
            "/Applications/Codex.app/Contents/MacOS/Codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "com.openai.codex",
            "com.openai.sky.CUAService"
        ]
    }

    private func permissionBrokerClients() -> [String] {
        [
            BridgeConstants.permissionBrokerBundleIdentifier,
            paths.installedPermissionBrokerExecutablePath.path,
            paths.builtPermissionBrokerExecutablePath.path
        ]
    }

    private func checkPermissionBrokerLaunchAgent() async -> DoctorCheck {
        let loaded = await ServiceLifecycle(paths: paths).permissionBrokerLaunchAgentLoaded()
        return loaded
            ? DoctorCheck(name: "Permission Broker LaunchAgent", ok: true, detail: BridgeConstants.permissionBrokerLaunchAgentLabel)
            : DoctorCheck(name: "Permission Broker LaunchAgent", ok: false, detail: "Start the bridge with codexmsgctl-swift start to load \(BridgeConstants.permissionBrokerLaunchAgentLabel).")
    }

    private func checkPermissionBrokerStatus() -> DoctorCheck {
        guard let status = readPermissionBrokerStatus(paths: paths) else {
            return DoctorCheck(name: "Permission Broker status", ok: false, detail: "No broker status file found yet.")
        }
        guard status.accessibilityTrusted else {
            return DoctorCheck(name: "Permission Broker status", ok: false, detail: status.lastSummary ?? "Accessibility is not trusted.")
        }
        return DoctorCheck(name: "Permission Broker status", ok: true, detail: status.lastSummary ?? "running")
    }

    private func checkTCC(_ name: String, services: [String], clients: [String], missingDetail: String) -> DoctorCheck {
        let db = "/Library/Application Support/com.apple.TCC/TCC.db"
        let serviceList = services.map { "'\($0)'" }.joined(separator: ",")
        let clientList = clients.map { "'\($0)'" }.joined(separator: ",")
        let sql = "select service,client from access where auth_value=2 and service in (\(serviceList)) and client in (\(clientList));"
        let output = (try? ProcessRunner().runSync("/usr/bin/sqlite3", [db, sql])) ?? ""
        return output.isEmpty
            ? DoctorCheck(name: name, ok: false, detail: missingDetail)
            : DoctorCheck(name: name, ok: true, detail: output.replacingOccurrences(of: "\n", with: "; "))
    }

    private func checkAppleEventsTarget(_ name: String, target: String) -> DoctorCheck {
        let db = "\(NSHomeDirectory())/Library/Application Support/com.apple.TCC/TCC.db"
        let clients = bridgeClients()
        let clientList = clients.map { "'\($0)'" }.joined(separator: ",")
        let sql = "select client from access where service='kTCCServiceAppleEvents' and auth_value=2 and indirect_object_identifier='\(target)' and client in (\(clientList));"
        let output = (try? ProcessRunner().runSync("/usr/bin/sqlite3", [db, sql])) ?? ""
        return output.isEmpty
            ? DoctorCheck(name: name, ok: false, detail: "Missing Automation grant to \(target); trigger the Computer Use probe from the signed app.")
            : DoctorCheck(name: name, ok: true, detail: output.replacingOccurrences(of: "\n", with: "; "))
    }

    private func computerUseProbe(_ config: BridgeConfig) async -> DoctorCheck {
        let prompt = "Use Computer Use to inspect Safari. First call list_apps, then get_app_state for Safari. Do not navigate or click. Reply only with SUCCESS and the Safari window title, or BLOCKED and the exact blocker text."
        let request = PromptRequest(promptText: prompt, attachments: [])
        do {
            let response = try await CodexAppServerBackend(config: config, paths: paths).invoke(request, sessionId: nil, onEvent: nil)
            let ok = response.text.localizedCaseInsensitiveContains("SUCCESS")
            return DoctorCheck(name: "Computer Use probe", ok: ok, detail: response.text)
        } catch let error as CodexBackendFailure {
            return DoctorCheck(name: "Computer Use probe", ok: false, detail: error.blockedText ?? error.message)
        } catch {
            return DoctorCheck(name: "Computer Use probe", ok: false, detail: String(describing: error))
        }
    }
}

public func runtimeDiagnosticChecks(paths: RuntimePaths = .current()) -> [DoctorCheck] {
    [
        DoctorCheck(name: "Running bundle path", ok: true, detail: Bundle.main.bundleURL.path),
        DoctorCheck(name: "Built app path", ok: true, detail: paths.builtAppPath.path),
        DoctorCheck(name: "Installed runtime app path", ok: true, detail: paths.installedAppPath.path),
        DoctorCheck(name: "Installed helper path", ok: true, detail: paths.installedHelperExecutablePath.path),
        DoctorCheck(name: "Installed permission broker path", ok: true, detail: paths.installedPermissionBrokerExecutablePath.path),
        DoctorCheck(name: "Config path", ok: true, detail: paths.configPath.path),
        DoctorCheck(name: "State path", ok: true, detail: paths.statePath.path),
        DoctorCheck(name: "Running bundle version", ok: true, detail: bundleShortVersion(at: Bundle.main.bundleURL) ?? "unknown"),
        DoctorCheck(name: "Installed app version", ok: true, detail: bundleShortVersion(at: paths.installedAppPath) ?? "unknown"),
        DoctorCheck(name: "Installed helper version", ok: true, detail: bundleShortVersion(at: installedHelperBundlePath(paths: paths)) ?? "unknown"),
        DoctorCheck(name: "Installed permission broker version", ok: true, detail: bundleShortVersion(at: installedPermissionBrokerBundlePath(paths: paths)) ?? "unknown"),
        DoctorCheck(name: "Installed app signing", ok: true, detail: codeSigningSummary(at: paths.installedAppPath)),
        DoctorCheck(name: "Installed helper signing", ok: true, detail: codeSigningSummary(at: installedHelperBundlePath(paths: paths))),
        DoctorCheck(name: "Installed permission broker signing", ok: true, detail: codeSigningSummary(at: installedPermissionBrokerBundlePath(paths: paths)))
    ]
}

public func installedHelperBundlePath(paths: RuntimePaths) -> URL {
    paths.installedAppPath.appendingPathComponent("Contents/Library/LoginItems/MessagesCodexBridgeHelper.app")
}

public func installedPermissionBrokerBundlePath(paths: RuntimePaths) -> URL {
    paths.installedAppPath.appendingPathComponent("Contents/Library/LoginItems/MessagesCodexPermissionBroker.app")
}

public func bundleShortVersion(at bundleURL: URL) -> String? {
    let infoPath = bundleURL.appendingPathComponent("Contents/Info.plist")
    guard let info = NSDictionary(contentsOf: infoPath) as? [String: Any] else { return nil }
    return info["CFBundleShortVersionString"] as? String
}

public func codeSigningSummary(at url: URL) -> String {
    guard FileManager.default.fileExists(atPath: url.path) else { return "missing" }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
    process.arguments = ["-dv", "--verbose=2", url.path]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return "codesign unavailable: \(error.localizedDescription)"
    }
    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    if output.localizedCaseInsensitiveContains("Signature=adhoc") {
        return "ad hoc"
    }
    let authorities = output
        .components(separatedBy: .newlines)
        .filter { $0.hasPrefix("Authority=") }
        .map { String($0.dropFirst("Authority=".count)) }
    if !authorities.isEmpty {
        return authorities.joined(separator: " > ")
    }
    if let team = output.components(separatedBy: .newlines).first(where: { $0.hasPrefix("TeamIdentifier=") }) {
        return team
    }
    return process.terminationStatus == 0 ? "signed" : "unsigned or invalid"
}

public extension ProcessRunner {
    func runSync(_ executable: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
