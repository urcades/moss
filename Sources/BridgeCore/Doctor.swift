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

public struct OutboundSmokeEvidence: Codable, Equatable, Sendable {
    public var rowId: Int64
    public var guid: String?
    public var dbError: Int
    public var transferState: Int?
    public var dateDelivered: Int64
    public var attachmentName: String?
    public var detail: String?

    public init(rowId: Int64, guid: String?, dbError: Int, transferState: Int? = nil, dateDelivered: Int64, attachmentName: String? = nil, detail: String? = nil) {
        self.rowId = rowId
        self.guid = guid
        self.dbError = dbError
        self.transferState = transferState
        self.dateDelivered = dateDelivered
        self.attachmentName = attachmentName
        self.detail = detail
    }
}

public struct CodexAppServerProcessSnapshot: Equatable, Sendable {
    public var pid: Int32
    public var parentPid: Int32
    public var processGroupId: Int32
    public var elapsed: String
    public var transport: String
    public var command: String

    public var isStdioTransport: Bool { transport == "stdio" }
    public var isOrphanedStdioTransport: Bool { isStdioTransport && parentPid == 1 }
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
        let state = try? stores.state.load()
        var checks: [DoctorCheck] = []
        checks.append(contentsOf: runtimeDiagnosticChecks(paths: paths))
        checks.append(checkStateRecoveryBackups())
        checks.append(checkCodex(config))
        checks.append(contentsOf: await checkCodexCapabilities(config))
        checks.append(checkTrustedSenders(config))
        checks.append(checkMessagesDb(config))
        checks.append(checkLastOutboundSend(state?.lastOutboundSend))
        checks.append(await checkRecentFailedOutboundEvidence(config))
        checks.append(checkCodexAppServerProcessSnapshot())
        checks.append(await checkMessagesAutomation(config))
        checks.append(await checkHelperLaunchAgent())
        checks.append(checkLaunchAgentProvenance(
            name: "Helper LaunchAgent provenance",
            label: BridgeConstants.helperLaunchAgentLabel,
            plistPath: paths.helperLaunchAgentPath,
            expectedExecutable: paths.installedHelperExecutablePath
        ))
        checks.append(checkTCC("Full Disk Access", services: ["kTCCServiceSystemPolicyAllFiles"], clients: bridgeClients(), missingDetail: "Grant Full Disk Access to Messages Codex Bridge so it can read Messages DB."))
        checks.append(checkTCC("Codex Accessibility", services: ["kTCCServiceAccessibility"], clients: codexComputerUseClients(), missingDetail: "Grant Accessibility to Codex and Codex Computer Use."))
        checks.append(checkTCC("Codex Screen Recording", services: ["kTCCServiceScreenCapture"], clients: codexComputerUseClients(), missingDetail: "Grant Screen Recording to Codex and Codex Computer Use."))
        checks.append(checkAppleEventsTarget("Automation: Computer Use", target: "com.openai.sky.CUAService"))
        checks.append(await checkPermissionBrokerLaunchAgent())
        checks.append(checkLaunchAgentProvenance(
            name: "Permission Broker LaunchAgent provenance",
            label: BridgeConstants.permissionBrokerLaunchAgentLabel,
            plistPath: paths.permissionBrokerLaunchAgentPath,
            expectedExecutable: paths.installedPermissionBrokerExecutablePath
        ))
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

    private func checkStateRecoveryBackups() -> DoctorCheck {
        let backups = recentStateRecoveryBackups(paths: paths, limit: 3)
        guard !backups.isEmpty else {
            return DoctorCheck(name: "State recovery backups", ok: true, detail: "none")
        }
        let allBackupCount = stateRecoveryBackupCount(paths: paths)
        let shown = backups.map(\.path).joined(separator: "; ")
        return DoctorCheck(name: "State recovery backups", ok: true, detail: "\(allBackupCount) corrupt state backup(s); latest \(shown)")
    }

    private func checkCodexCapabilities(_ config: BridgeConfig) async -> [DoctorCheck] {
        guard let snapshot = await asyncTimeout(nanoseconds: 15_000_000_000, operation: { [runner, paths] in
            await cachedCodexCapabilities(command: config.codex.command, runner: runner, paths: paths, ttlMs: Int.max)
        }) else {
            return [
                DoctorCheck(
                    name: "Codex capability cache",
                    ok: false,
                    detail: "Timed out after 15s while reading Codex app-server capabilities; use status cache or rerun later."
                )
            ]
        }
        let capabilities = snapshot.capabilities
        var checks = [
            DoctorCheck(name: "Codex capability cache", ok: true, detail: snapshot.refreshed ? "refreshed at \(snapshot.cachedAt)" : "cached at \(snapshot.cachedAt), age \(snapshot.cacheAgeSeconds ?? 0)s"),
            DoctorCheck(name: "Codex version", ok: true, detail: capabilities.version ?? "unknown"),
            DoctorCheck(name: "Codex app-server", ok: true, detail: capabilities.appServerAvailable ? "yes" : "no"),
            DoctorCheck(name: "Codex remote-control", ok: true, detail: capabilities.remoteControlAvailable ? "yes" : "no"),
            DoctorCheck(name: "Codex thread/read", ok: true, detail: capabilities.threadReadAvailable ? "yes" : "no"),
            DoctorCheck(name: "Codex enhanced bridge UX", ok: true, detail: capabilities.enhancedBridgeUXAvailable ? "yes" : "degraded")
        ]
        if let inventory = capabilities.inventory {
            checks.append(DoctorCheck(name: "Codex skills inventory", ok: true, detail: "\(inventory.enabledSkillCount) enabled / \(inventory.skills.count) total\(doctorSampleSuffix(inventory.skills.map(\.name)))"))
            checks.append(DoctorCheck(name: "Codex plugins inventory", ok: true, detail: "\(inventory.plugins.count)\(doctorSampleSuffix(inventory.plugins.map { $0.displayName ?? $0.name }))"))
            checks.append(DoctorCheck(name: "Codex apps/connectors inventory", ok: true, detail: "\(inventory.accessibleAppCount) accessible / \(inventory.apps.count) total\(doctorSampleSuffix(inventory.apps.filter(\.isAccessible).map(\.name)))"))
            checks.append(DoctorCheck(name: "Codex MCP inventory", ok: true, detail: "\(inventory.mcpServers.count) server(s), \(inventory.mcpToolCount) tool(s)\(doctorSampleSuffix(inventory.mcpServers.map(\.name)))"))
        } else {
            checks.append(DoctorCheck(name: "Codex tool inventory", ok: false, detail: "Unavailable from app-server."))
        }
        checks += capabilities.warnings.map { DoctorCheck(name: "Codex capability warning", ok: true, detail: $0) }
        return checks
    }

    private func doctorSampleSuffix(_ values: [String], limit: Int = 5) -> String {
        let names = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else { return "" }
        let shown = names.prefix(limit).joined(separator: ", ")
        return names.count > limit ? " (\(shown), ...)" : " (\(shown))"
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

    private func checkRecentFailedOutboundEvidence(_ config: BridgeConfig) async -> DoctorCheck {
        do {
            let failures = try await recentFailedOutboundEvidence(config: config, limit: 3, runner: runner)
            guard !failures.isEmpty else {
                return DoctorCheck(name: "Recent failed outbound evidence", ok: true, detail: "No recent failed outgoing Messages rows found.")
            }
            return DoctorCheck(name: "Recent failed outbound evidence", ok: true, detail: formatRecentFailedOutboundEvidence(failures))
        } catch {
            return DoctorCheck(name: "Recent failed outbound evidence", ok: true, detail: "Unavailable: \(error)")
        }
    }

    private func checkLastOutboundSend(_ send: OutboundSendRecord?) -> DoctorCheck {
        guard let send else {
            return DoctorCheck(name: "Last outbound send", ok: true, detail: "none")
        }
        let failed = send.retryable || send.status.localizedCaseInsensitiveContains("fail")
        return DoctorCheck(name: "Last outbound send", ok: !failed, detail: outboundSendStatusText(send))
    }

    private func checkCodexAppServerProcessSnapshot() -> DoctorCheck {
        let output = (try? runner.runSync("/bin/ps", ["-axo", "pid=,ppid=,pgid=,etime=,command="])) ?? ""
        let snapshots = codexAppServerProcessSnapshots(from: output)
        guard !snapshots.isEmpty else {
            return DoctorCheck(name: "Codex app-server processes", ok: true, detail: "none")
        }
        let orphanedStdio = snapshots.filter(\.isOrphanedStdioTransport)
        let transportCounts = Dictionary(grouping: snapshots, by: \.transport)
            .map { "\($0.key) \($0.value.count)" }
            .sorted()
            .joined(separator: ", ")
        let sample = snapshots.prefix(6).map { snapshot in
            "\(snapshot.pid)(ppid \(snapshot.parentPid), \(snapshot.transport), \(snapshot.elapsed))"
        }.joined(separator: ", ")
        let detail = [
            "\(snapshots.count) running",
            transportCounts,
            "orphaned stdio \(orphanedStdio.count)",
            "sample \(sample)"
        ].joined(separator: "; ")
        return DoctorCheck(name: "Codex app-server processes", ok: orphanedStdio.isEmpty, detail: detail)
    }

    private func checkMessagesAutomation(_ config: BridgeConfig) async -> DoctorCheck {
        let script = #"tell application "Messages" to get id of 1st service whose service type = iMessage"#
        do {
            let result = try await runner.run(config.osascriptCommand, ["-e", script], timeoutMs: 10_000)
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

    private func checkHelperLaunchAgent() async -> DoctorCheck {
        let loaded = await ServiceLifecycle(paths: paths).helperLaunchAgentLoaded()
        return loaded
            ? DoctorCheck(name: "Helper LaunchAgent", ok: true, detail: BridgeConstants.helperLaunchAgentLabel)
            : DoctorCheck(name: "Helper LaunchAgent", ok: false, detail: "Start the bridge with codexmsgctl-swift start to load \(BridgeConstants.helperLaunchAgentLabel).")
    }

    private func checkLaunchAgentProvenance(name: String, label: String, plistPath: URL, expectedExecutable: URL) -> DoctorCheck {
        let expected = expectedExecutable.standardizedFileURL.path
        guard let plistProgram = launchAgentProgramArgument(at: plistPath) else {
            return DoctorCheck(name: name, ok: false, detail: "Missing or unreadable LaunchAgent plist at \(plistPath.path).")
        }
        let plistMatches = URL(fileURLWithPath: plistProgram).standardizedFileURL.path == expected
        let loadedProgram = (try? runner.runSync("/bin/launchctl", ["print", "gui/\(getuid())/\(label)"], timeoutMs: 5_000)).flatMap(launchctlProgram)
        let loadedMatches = loadedProgram.map { URL(fileURLWithPath: $0).standardizedFileURL.path == expected }
        var parts = [
            "expected \(expected)",
            "plist \(plistProgram)"
        ]
        if let loadedProgram {
            parts.append("loaded \(loadedProgram)")
        } else {
            parts.append("loaded unavailable")
        }
        let ok = plistMatches && (loadedMatches ?? true)
        return DoctorCheck(name: name, ok: ok, detail: parts.joined(separator: "; "))
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
        let pidBox = LockedPid()
        do {
            let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CodexResponse, Error>) in
                let resumeOnce = ResumeOnce()
                let probeTask = Task {
                    do {
                        let response = try await CodexAppServerBackend(config: config, paths: paths).invoke(request, sessionId: nil) { event in
                            if case .processStarted(let pid) = event {
                                pidBox.set(pid)
                            }
                        }
                        resumeOnce.run {
                            continuation.resume(returning: response)
                        }
                    } catch {
                        resumeOnce.run {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                Task {
                    try? await Task.sleep(nanoseconds: 45_000_000_000)
                    resumeOnce.run {
                        probeTask.cancel()
                        if let pid = pidBox.get() {
                            terminateProcessTree(rootPid: pid)
                        }
                        continuation.resume(throwing: StoreError.validation("Computer Use probe timed out after 45s."))
                    }
                }
            }
            let ok = response.text.localizedCaseInsensitiveContains("SUCCESS")
            return DoctorCheck(name: "Computer Use probe", ok: ok, detail: response.text)
        } catch let error as CodexBackendFailure {
            return DoctorCheck(name: "Computer Use probe", ok: false, detail: error.blockedText ?? error.message)
        } catch {
            return DoctorCheck(name: "Computer Use probe", ok: false, detail: String(describing: error))
        }
    }
}

private func asyncTimeout<T: Sendable>(nanoseconds: UInt64, operation: @escaping @Sendable () async -> T) async -> T? {
    await withCheckedContinuation { continuation in
        let resumeOnce = ResumeOnce()
        let task = Task {
            let value = await operation()
            resumeOnce.run {
                continuation.resume(returning: value)
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: nanoseconds)
            resumeOnce.run {
                task.cancel()
                continuation.resume(returning: nil)
            }
        }
    }
}

private final class LockedPid: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int32?

    func set(_ newValue: Int32) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    func get() -> Int32? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    func run(_ body: () -> Void) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }
        didResume = true
        lock.unlock()
        body()
    }
}

public func stateRecoveryBackupCount(paths: RuntimePaths = .current()) -> Int {
    let prefix = "\(paths.statePath.lastPathComponent).corrupt-"
    let names = (try? FileManager.default.contentsOfDirectory(atPath: paths.stateDir.path)) ?? []
    return names.filter { $0.hasPrefix(prefix) }.count
}

public func recentStateRecoveryBackups(paths: RuntimePaths = .current(), limit: Int = 3) -> [URL] {
    let prefix = "\(paths.statePath.lastPathComponent).corrupt-"
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: paths.stateDir.path) else {
        return []
    }
    return names
        .filter { $0.hasPrefix(prefix) }
        .map { paths.stateDir.appendingPathComponent($0) }
        .sorted { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            if lhsDate == rhsDate {
                return lhs.lastPathComponent > rhs.lastPathComponent
            }
            return lhsDate > rhsDate
        }
        .prefix(limit)
        .map { $0 }
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
    ] + [
        runtimeExecutableIdentityCheck(
            name: "Helper built-vs-installed identity",
            built: paths.builtHelperExecutablePath,
            installed: paths.installedHelperExecutablePath
        ),
        runtimeExecutableIdentityCheck(
            name: "Permission broker built-vs-installed identity",
            built: paths.builtPermissionBrokerExecutablePath,
            installed: paths.installedPermissionBrokerExecutablePath
        )
    ]
}

public func runtimeExecutableIdentityCheck(name: String, built: URL, installed: URL) -> DoctorCheck {
    let fm = FileManager.default
    guard fm.fileExists(atPath: installed.path) else {
        return DoctorCheck(name: name, ok: false, detail: "Installed executable missing at \(installed.path)")
    }
    guard fm.fileExists(atPath: built.path) else {
        return DoctorCheck(name: name, ok: true, detail: "Not comparable: built executable missing at \(built.path)")
    }
    do {
        let builtData = try Data(contentsOf: built)
        let installedData = try Data(contentsOf: installed)
        let builtStamp = fileModificationSummary(built)
        let installedStamp = fileModificationSummary(installed)
        if builtData == installedData {
            return DoctorCheck(name: name, ok: true, detail: "match; bytes \(builtData.count); built \(builtStamp); installed \(installedStamp)")
        }
        return DoctorCheck(name: name, ok: false, detail: "mismatch; built bytes \(builtData.count) \(builtStamp); installed bytes \(installedData.count) \(installedStamp)")
    } catch {
        return DoctorCheck(name: name, ok: false, detail: "Unable to compare \(built.path) and \(installed.path): \(error)")
    }
}

private func fileModificationSummary(_ url: URL) -> String {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
          let date = attrs[.modificationDate] as? Date else {
        return "mtime unknown"
    }
    return "mtime \(DateCodec.iso(date))"
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

public func launchAgentProgramArgument(at plistPath: URL) -> String? {
    guard let data = try? Data(contentsOf: plistPath),
          let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
          let dict = plist as? [String: Any],
          let arguments = dict["ProgramArguments"] as? [String],
          let first = arguments.first,
          !first.isEmpty else {
        return nil
    }
    return first
}

public func launchctlProgram(from output: String) -> String? {
    for line in output.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("program = ") else { continue }
        let value = String(trimmed.dropFirst("program = ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    return nil
}

public extension ProcessRunner {
    func runSync(_ executable: String, _ arguments: [String], timeoutMs: Int? = 10_000) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        let timedOut = LockedBool()
        try process.run()
        if let timeoutMs, timeoutMs > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
                if process.isRunning {
                    timedOut.set(true)
                    process.terminate()
                }
            }
        }
        process.waitUntilExit()
        if timedOut.get() {
            throw ProcessRunnerError.timedOut("\(executable) timed out after \(timeoutMs ?? 0)ms")
        }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

private final class LockedBool: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set(_ newValue: Bool) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    func get() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

public func latestOutgoingMessageRowId(config: BridgeConfig, runner: ProcessRunner = ProcessRunner()) async throws -> Int64 {
    let sql = "SELECT COALESCE(MAX(ROWID), 0) FROM message WHERE is_from_me = 1;"
    let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", config.messagesDbPath, sql])
    return Int64(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
}

public func outboundSmokeTextEvidence(marker: String, afterRowId: Int64, config: BridgeConfig, runner: ProcessRunner = ProcessRunner()) async throws -> OutboundSmokeEvidence? {
    let markerLiteral = sqliteStringLiteral("%\(marker)%")
    let markerExact = sqliteStringLiteral(marker)
    let sql = """
    SELECT m.ROWID || '|' || COALESCE(m.guid, '') || '|' || COALESCE(m.error, 0) || '|' || COALESCE(m.date_delivered, 0)
    FROM message m
    WHERE m.is_from_me = 1
      AND m.ROWID > \(afterRowId)
      AND (
        COALESCE(m.text, '') LIKE \(markerLiteral)
        OR instr(COALESCE(m.attributedBody, x''), CAST(\(markerExact) AS BLOB)) > 0
      )
    ORDER BY m.ROWID DESC
    LIMIT 1;
    """
    let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", config.messagesDbPath, sql])
    let fields = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    guard fields.count == 4, let rowId = Int64(fields[0]) else { return nil }
    return OutboundSmokeEvidence(
        rowId: rowId,
        guid: fields[1].isEmpty ? nil : fields[1],
        dbError: Int(fields[2]) ?? 0,
        dateDelivered: Int64(fields[3]) ?? 0,
        detail: "matched outbound marker"
    )
}

public func codexAppServerProcessSnapshots(from psOutput: String) -> [CodexAppServerProcessSnapshot] {
    psOutput
        .split(whereSeparator: \.isNewline)
        .compactMap { line -> CodexAppServerProcessSnapshot? in
            let parts = line.split(maxSplits: 4, whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count == 5,
                  let pid = Int32(parts[0]),
                  let parentPid = Int32(parts[1]),
                  let processGroupId = Int32(parts[2]) else {
                return nil
            }
            let command = parts[4]
            let executable = command.split(maxSplits: 1, whereSeparator: \.isWhitespace).first.map(String.init) ?? ""
            guard (executable == "codex" || executable.hasSuffix("/codex")),
                  command.contains("app-server") else { return nil }
            let transport: String
            if command.contains("--listen stdio://") {
                transport = "stdio"
            } else if command.contains("--listen unix://") {
                transport = "unix"
            } else if command.contains("--analytics-default-enabled") {
                transport = "desktop"
            } else {
                transport = "unknown"
            }
            return CodexAppServerProcessSnapshot(
                pid: pid,
                parentPid: parentPid,
                processGroupId: processGroupId,
                elapsed: parts[3],
                transport: transport,
                command: command
            )
        }
}

public func outboundSmokeAttachmentEvidence(marker: String, afterRowId: Int64, config: BridgeConfig, runner: ProcessRunner = ProcessRunner()) async throws -> OutboundSmokeEvidence? {
    let literal = sqliteStringLiteral(marker)
    let sql = """
    SELECT m.ROWID || '|' || COALESCE(m.guid, '') || '|' || COALESCE(m.error, 0) || '|' || COALESCE(a.transfer_state, '') || '|' || COALESCE(m.date_delivered, 0) || '|' || COALESCE(a.transfer_name, '') || '|' || CASE WHEN instr(COALESCE(a.transfer_name, ''), \(literal)) > 0 THEN 1 ELSE 0 END
    FROM message m
    JOIN message_attachment_join maj ON maj.message_id = m.ROWID
    JOIN attachment a ON a.ROWID = maj.attachment_id
    WHERE m.is_from_me = 1
      AND m.ROWID > \(afterRowId)
    ORDER BY CASE WHEN instr(COALESCE(a.transfer_name, ''), \(literal)) > 0 THEN 1 ELSE 0 END DESC, m.ROWID DESC
    LIMIT 1;
    """
    let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", config.messagesDbPath, sql])
    let fields = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    guard fields.count == 7, let rowId = Int64(fields[0]) else { return nil }
    let matchedMarker = fields[6] == "1"
    return OutboundSmokeEvidence(
        rowId: rowId,
        guid: fields[1].isEmpty ? nil : fields[1],
        dbError: Int(fields[2]) ?? 0,
        transferState: fields[3].isEmpty ? nil : Int(fields[3]),
        dateDelivered: Int64(fields[4]) ?? 0,
        attachmentName: fields[5].isEmpty ? nil : fields[5],
        detail: matchedMarker ? "matched outbound attachment marker" : "matched latest outbound attachment after baseline"
    )
}

public func recentFailedOutboundEvidence(config: BridgeConfig, limit: Int = 5, runner: ProcessRunner = ProcessRunner()) async throws -> [OutboundSmokeEvidence] {
    let boundedLimit = max(1, min(limit, 50))
    let sql = """
    SELECT m.ROWID || '|' || COALESCE(m.guid, '') || '|' || COALESCE(m.error, 0) || '|' || COALESCE(a.transfer_state, '') || '|' || COALESCE(m.date_delivered, 0) || '|' || COALESCE(a.transfer_name, '')
    FROM message m
    LEFT JOIN message_attachment_join maj ON maj.message_id = m.ROWID
    LEFT JOIN attachment a ON a.ROWID = maj.attachment_id
    WHERE m.is_from_me = 1
      AND (
        COALESCE(m.error, 0) != 0
        OR COALESCE(a.transfer_state, 0) = 6
        OR (a.ROWID IS NOT NULL AND COALESCE(m.date_delivered, 0) = 0)
      )
    ORDER BY m.ROWID DESC
    LIMIT \(boundedLimit);
    """
    let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", config.messagesDbPath, sql])
    return result.stdout
        .split(separator: "\n")
        .compactMap { line -> OutboundSmokeEvidence? in
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6, let rowId = Int64(fields[0]) else { return nil }
            return OutboundSmokeEvidence(
                rowId: rowId,
                guid: fields[1].isEmpty ? nil : fields[1],
                dbError: Int(fields[2]) ?? 0,
                transferState: fields[3].isEmpty ? nil : Int(fields[3]),
                dateDelivered: Int64(fields[4]) ?? 0,
                attachmentName: fields[5].isEmpty ? nil : fields[5],
                detail: "recent failed outbound Messages row"
            )
        }
}

public func formatRecentFailedOutboundEvidence(_ failures: [OutboundSmokeEvidence]) -> String {
    guard !failures.isEmpty else { return "No recent failed outbound Messages rows found." }
    return failures.map { failure in
        var parts = [
            "row \(failure.rowId)",
            "guid \(failure.guid ?? "unknown")",
            "error \(failure.dbError)",
            "date_delivered \(failure.dateDelivered)"
        ]
        if let transferState = failure.transferState {
            parts.append("transfer_state \(transferState)")
        }
        if let attachmentName = failure.attachmentName {
            parts.append("attachment \(attachmentName)")
        }
        return parts.joined(separator: "; ")
    }.joined(separator: "\n")
}
