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

public final class ServiceLifecycle {
    private let paths: RuntimePaths
    private let runner = ProcessRunner()

    public init(paths: RuntimePaths = .current()) {
        self.paths = paths
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

    public func startHelperLaunchAgent() async throws {
        await stopHelperLaunchAgent(removePlist: false)
        await stopPermissionBrokerLaunchAgent(removePlist: false)
        try installApplicationBundle()
        try installHelperLaunchAgent()
        try installPermissionBrokerLaunchAgent()
        _ = try await runner.run("/bin/launchctl", ["bootstrap", "gui/\(getuid())", paths.helperLaunchAgentPath.path])
        _ = try? await runner.run("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(BridgeConstants.helperLaunchAgentLabel)"])
        _ = try await runner.run("/bin/launchctl", ["bootstrap", "gui/\(getuid())", paths.permissionBrokerLaunchAgentPath.path])
        _ = try? await runner.run("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(BridgeConstants.permissionBrokerLaunchAgentLabel)"])
    }

    public func startPermissionBrokerLaunchAgent() async throws {
        await stopPermissionBrokerLaunchAgent(removePlist: false)
        if !FileManager.default.fileExists(atPath: paths.installedPermissionBrokerExecutablePath.path) {
            try installApplicationBundle()
        }
        try installPermissionBrokerLaunchAgent()
        _ = try await runner.run("/bin/launchctl", ["bootstrap", "gui/\(getuid())", paths.permissionBrokerLaunchAgentPath.path])
        _ = try? await runner.run("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(BridgeConstants.permissionBrokerLaunchAgentLabel)"])
    }

    public func installApplicationBundle() throws {
        guard FileManager.default.fileExists(atPath: paths.builtAppPath.path) else {
            throw StoreError.validation("Built app bundle not found at \(paths.builtAppPath.path). Run BuildSupport/build-app.zsh first.")
        }
        try FileManager.default.createDirectory(at: paths.installedAppPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: paths.installedAppPath.path) {
            try FileManager.default.removeItem(at: paths.installedAppPath)
        }
        try FileManager.default.copyItem(at: paths.builtAppPath, to: paths.installedAppPath)
    }

    public func stopHelperLaunchAgent(removePlist: Bool = false) async {
        _ = try? await runner.run("/bin/launchctl", ["bootout", "gui/\(getuid())", paths.helperLaunchAgentPath.path])
        _ = try? await runner.run("/bin/launchctl", ["remove", BridgeConstants.helperLaunchAgentLabel])
        if removePlist {
            try? FileManager.default.removeItem(at: paths.helperLaunchAgentPath)
        }
    }

    public func stopPermissionBrokerLaunchAgent(removePlist: Bool = false) async {
        _ = try? await runner.run("/bin/launchctl", ["bootout", "gui/\(getuid())", paths.permissionBrokerLaunchAgentPath.path])
        _ = try? await runner.run("/bin/launchctl", ["remove", BridgeConstants.permissionBrokerLaunchAgentLabel])
        if removePlist {
            try? FileManager.default.removeItem(at: paths.permissionBrokerLaunchAgentPath)
        }
    }

    public func helperLaunchAgentLoaded() async -> Bool {
        (try? await runner.run("/bin/launchctl", ["print", "gui/\(getuid())/\(BridgeConstants.helperLaunchAgentLabel)"])) != nil
    }

    public func permissionBrokerLaunchAgentLoaded() async -> Bool {
        (try? await runner.run("/bin/launchctl", ["print", "gui/\(getuid())/\(BridgeConstants.permissionBrokerLaunchAgentLabel)"])) != nil
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
