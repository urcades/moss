import Foundation

public struct MigrationReport: Equatable {
    public var backupDir: URL?
    public var lastProcessedRowId: Int64
}

public final class Migration {
    private let paths: RuntimePaths

    public init(paths: RuntimePaths = .current()) {
        self.paths = paths
    }

    public func migrateFromExistingRuntime(backup: Bool = true) throws -> MigrationReport {
        try ensureRuntimeDirectories(paths)
        let backupDir = backup ? try backupRuntime() : nil
        let stores = RuntimeStores(paths: paths)
        var config = (try? stores.config.load()) ?? defaultBridgeConfig(paths: paths)
        if config.codex.command == "codex" {
            config.codex.command = "/Applications/Codex.app/Contents/Resources/codex"
        }
        migrateTrustedSenders(&config)
        try validateConfig(config)
        try stores.config.save(config)
        let state = (try? stores.state.load()) ?? defaultBridgeState()
        try stores.state.save(state)
        return MigrationReport(backupDir: backupDir, lastProcessedRowId: state.lastProcessedRowId)
    }

    private func backupRuntime() throws -> URL {
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let dir = paths.appSupportDir.appendingPathComponent("backups/swift-\(stamp)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for url in [paths.configPath, paths.statePath] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.copyItem(at: url, to: dir.appendingPathComponent(url.lastPathComponent))
        }
        return dir
    }
}

public func migrateTrustedSenders(_ config: inout BridgeConfig) {
    let trusted = normalizedTrustedSenderList(config.trustedSenders ?? [])
    if trusted.isEmpty {
        config.syncTrustedSenders([config.allowedSender])
    } else {
        config.syncTrustedSenders(trusted)
    }
}

public enum LaunchAgentLoadState: Equatable, Sendable {
    case loaded
    case notLoaded
    case error(String)

    public var isLoaded: Bool {
        self == .loaded
    }

    public var statusText: String {
        switch self {
        case .loaded:
            return "loaded"
        case .notLoaded:
            return "not loaded"
        case .error(let detail):
            return "error: \(detail)"
        }
    }
}

public final class ServiceLifecycle {
    private let paths: RuntimePaths
    private let launchctlCommand: String
    private let runner = ProcessRunner()

    public init(paths: RuntimePaths = .current(), launchctlCommand: String = "/bin/launchctl") {
        self.paths = paths
        self.launchctlCommand = launchctlCommand
    }

    public func installHelperLaunchAgent(helperExecutable: URL? = nil) throws {
        let executable = helperExecutable ?? paths.installedHelperExecutablePath
        guard FileManager.default.fileExists(atPath: executable.path) else {
            throw StoreError.validation("Helper executable not found at \(executable.path). Run BuildSupport/build-app.zsh and codexmsgctl-swift start first.")
        }
        try FileManager.default.createDirectory(at: paths.launchAgentsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: paths.logsDir, withIntermediateDirectories: true)
        let data = try helperLaunchAgentPlistData(paths: paths, helperExecutable: executable)
        try data.write(to: paths.helperLaunchAgentPath, options: .atomic)
    }

    public func installPermissionBrokerLaunchAgent(brokerExecutable: URL? = nil) throws {
        let executable = brokerExecutable ?? paths.installedPermissionBrokerExecutablePath
        guard FileManager.default.fileExists(atPath: executable.path) else {
            throw StoreError.validation("Permission broker executable not found at \(executable.path). Run BuildSupport/build-app.zsh and codexmsgctl-swift start first.")
        }
        try FileManager.default.createDirectory(at: paths.launchAgentsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: paths.logsDir, withIntermediateDirectories: true)
        let data = try permissionBrokerLaunchAgentPlistData(paths: paths, brokerExecutable: executable)
        try data.write(to: paths.permissionBrokerLaunchAgentPath, options: .atomic)
    }

    public func startHelperLaunchAgent(appBundle: URL? = nil) async throws {
        await stopHelperLaunchAgent(removePlist: false)
        await stopPermissionBrokerLaunchAgent(removePlist: false)
        try installApplicationBundle(sourceAppPath: appBundle)
        try installHelperLaunchAgent()
        try installPermissionBrokerLaunchAgent()
        _ = try await runner.run(launchctlCommand, ["bootstrap", "gui/\(getuid())", paths.helperLaunchAgentPath.path], timeoutMs: 10_000)
        _ = try? await runner.run(launchctlCommand, ["kickstart", "-k", "gui/\(getuid())/\(BridgeConstants.helperLaunchAgentLabel)"], timeoutMs: 10_000)
        _ = try await runner.run(launchctlCommand, ["bootstrap", "gui/\(getuid())", paths.permissionBrokerLaunchAgentPath.path], timeoutMs: 10_000)
        _ = try? await runner.run(launchctlCommand, ["kickstart", "-k", "gui/\(getuid())/\(BridgeConstants.permissionBrokerLaunchAgentLabel)"], timeoutMs: 10_000)
    }

    public func startPermissionBrokerLaunchAgent() async throws {
        await stopPermissionBrokerLaunchAgent(removePlist: false)
        if !FileManager.default.fileExists(atPath: paths.installedPermissionBrokerExecutablePath.path) {
            try installApplicationBundle()
        }
        try installPermissionBrokerLaunchAgent()
        _ = try await runner.run(launchctlCommand, ["bootstrap", "gui/\(getuid())", paths.permissionBrokerLaunchAgentPath.path], timeoutMs: 10_000)
        _ = try? await runner.run(launchctlCommand, ["kickstart", "-k", "gui/\(getuid())/\(BridgeConstants.permissionBrokerLaunchAgentLabel)"], timeoutMs: 10_000)
    }

    public func installApplicationBundle(sourceAppPath: URL? = nil) throws {
        let source = sourceAppPath ?? paths.builtAppPath
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw StoreError.validation("App bundle not found at \(source.path). Run BuildSupport/build-app.zsh first.")
        }
        if source.standardizedFileURL.path == paths.installedAppPath.standardizedFileURL.path {
            return
        }
        try FileManager.default.createDirectory(at: paths.installedAppPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: paths.installedAppPath.path) {
            try FileManager.default.removeItem(at: paths.installedAppPath)
        }
        try FileManager.default.copyItem(at: source, to: paths.installedAppPath)
    }

    public func stopHelperLaunchAgent(removePlist: Bool = false) async {
        _ = try? await runner.run(launchctlCommand, ["bootout", "gui/\(getuid())", paths.helperLaunchAgentPath.path], timeoutMs: 10_000)
        _ = try? await runner.run(launchctlCommand, ["remove", BridgeConstants.helperLaunchAgentLabel], timeoutMs: 10_000)
        if removePlist {
            try? FileManager.default.removeItem(at: paths.helperLaunchAgentPath)
        }
    }

    public func stopPermissionBrokerLaunchAgent(removePlist: Bool = false) async {
        _ = try? await runner.run(launchctlCommand, ["bootout", "gui/\(getuid())", paths.permissionBrokerLaunchAgentPath.path], timeoutMs: 10_000)
        _ = try? await runner.run(launchctlCommand, ["remove", BridgeConstants.permissionBrokerLaunchAgentLabel], timeoutMs: 10_000)
        if removePlist {
            try? FileManager.default.removeItem(at: paths.permissionBrokerLaunchAgentPath)
        }
    }

    public func helperLaunchAgentLoaded() async -> Bool {
        (await helperLaunchAgentState()).isLoaded
    }

    public func permissionBrokerLaunchAgentLoaded() async -> Bool {
        (await permissionBrokerLaunchAgentState()).isLoaded
    }

    public func helperLaunchAgentState() async -> LaunchAgentLoadState {
        await launchAgentState(label: BridgeConstants.helperLaunchAgentLabel)
    }

    public func permissionBrokerLaunchAgentState() async -> LaunchAgentLoadState {
        await launchAgentState(label: BridgeConstants.permissionBrokerLaunchAgentLabel)
    }

    private func launchAgentState(label: String) async -> LaunchAgentLoadState {
        let domain = "gui/\(getuid())"
        if (try? await runner.run(launchctlCommand, ["print", "\(domain)/\(label)"], timeoutMs: 5_000)) != nil {
            return .loaded
        }
        do {
            let domainPrint = try await runner.run(launchctlCommand, ["print", domain], timeoutMs: 5_000)
            return domainPrint.stdout.contains(label) ? .loaded : .notLoaded
        } catch {
            return .error(String(describing: error))
        }
    }
}

public func helperLaunchAgentPlistData(paths: RuntimePaths, helperExecutable: URL) throws -> Data {
    let plist: [String: Any] = [
        "Label": BridgeConstants.helperLaunchAgentLabel,
        "ProgramArguments": [helperExecutable.path],
        "RunAtLoad": true,
        "KeepAlive": true,
        "StandardOutPath": paths.logsDir.appendingPathComponent("launchagent.out.log").path,
        "StandardErrorPath": paths.logsDir.appendingPathComponent("launchagent.err.log").path,
        "EnvironmentVariables": [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
        ]
    ]
    return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
}

public func permissionBrokerLaunchAgentPlistData(paths: RuntimePaths, brokerExecutable: URL) throws -> Data {
    let plist: [String: Any] = [
        "Label": BridgeConstants.permissionBrokerLaunchAgentLabel,
        "ProgramArguments": [brokerExecutable.path],
        "RunAtLoad": true,
        "KeepAlive": true,
        "StandardOutPath": paths.logsDir.appendingPathComponent("permission-broker.out.log").path,
        "StandardErrorPath": paths.logsDir.appendingPathComponent("permission-broker.err.log").path,
        "EnvironmentVariables": [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
        ]
    ]
    return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
}
