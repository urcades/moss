import Foundation

public struct RuntimePaths: Equatable, Sendable {
    public var homeDir: URL
    public var projectRoot: URL
    public var defaultCodexCwd: URL
    public var appSupportDir: URL
    public var stateDir: URL
    public var tmpDir: URL
    public var logsDir: URL
    public var launchAgentsDir: URL
    public var configPath: URL
    public var statePath: URL
    public var permissionBrokerDir: URL
    public var permissionBrokerStatusPath: URL
    public var permissionBrokerEventsPath: URL
    public var helperLaunchAgentPath: URL
    public var permissionBrokerLaunchAgentPath: URL
    public var builtAppPath: URL
    public var builtHelperExecutablePath: URL
    public var builtPermissionBrokerExecutablePath: URL
    public var installedAppPath: URL
    public var installedHelperExecutablePath: URL
    public var installedPermissionBrokerExecutablePath: URL
    public var defaultMessagesDbPath: URL

    public static func current(projectRoot: URL? = nil, environment: [String: String] = ProcessInfo.processInfo.environment) -> RuntimePaths {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let root = projectRoot ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let appSupport = URL(fileURLWithPath: environment["MESSAGES_LLM_BRIDGE_HOME"] ?? home.appendingPathComponent("Library/Application Support/\(BridgeConstants.appName)").path)
        let logs = URL(fileURLWithPath: environment["MESSAGES_LLM_BRIDGE_LOG_DIR"] ?? home.appendingPathComponent("Library/Logs/\(BridgeConstants.appName)").path)
        let launchAgents = URL(fileURLWithPath: environment["MESSAGES_LLM_BRIDGE_LAUNCH_AGENTS_DIR"] ?? home.appendingPathComponent("Library/LaunchAgents").path)
        let state = appSupport.appendingPathComponent("state")
        return RuntimePaths(
            homeDir: home,
            projectRoot: root,
            defaultCodexCwd: root,
            appSupportDir: appSupport,
            stateDir: state,
            tmpDir: appSupport.appendingPathComponent("tmp"),
            logsDir: logs,
            launchAgentsDir: launchAgents,
            configPath: appSupport.appendingPathComponent("config.json"),
            statePath: state.appendingPathComponent("state.json"),
            permissionBrokerDir: state.appendingPathComponent("permission-broker"),
            permissionBrokerStatusPath: state.appendingPathComponent("permission-broker/status.json"),
            permissionBrokerEventsPath: state.appendingPathComponent("permission-broker/events.jsonl"),
            helperLaunchAgentPath: launchAgents.appendingPathComponent("\(BridgeConstants.helperLaunchAgentLabel).plist"),
            permissionBrokerLaunchAgentPath: launchAgents.appendingPathComponent("\(BridgeConstants.permissionBrokerLaunchAgentLabel).plist"),
            builtAppPath: root.appendingPathComponent(".build/app/MessagesCodexBridge.app"),
            builtHelperExecutablePath: root.appendingPathComponent(".build/app/MessagesCodexBridge.app/Contents/Library/LoginItems/MessagesCodexBridgeHelper.app/Contents/MacOS/MessagesCodexBridgeHelper"),
            builtPermissionBrokerExecutablePath: root.appendingPathComponent(".build/app/MessagesCodexBridge.app/Contents/Library/LoginItems/MessagesCodexPermissionBroker.app/Contents/MacOS/MessagesCodexPermissionBroker"),
            installedAppPath: appSupport.appendingPathComponent("Applications/MessagesCodexBridge.app"),
            installedHelperExecutablePath: appSupport.appendingPathComponent("Applications/MessagesCodexBridge.app/Contents/Library/LoginItems/MessagesCodexBridgeHelper.app/Contents/MacOS/MessagesCodexBridgeHelper"),
            installedPermissionBrokerExecutablePath: appSupport.appendingPathComponent("Applications/MessagesCodexBridge.app/Contents/Library/LoginItems/MessagesCodexPermissionBroker.app/Contents/MacOS/MessagesCodexPermissionBroker"),
            defaultMessagesDbPath: home.appendingPathComponent("Library/Messages/chat.db")
        )
    }
}

public enum DateCodec {
    private static func formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    public static func iso(_ date: Date = Date()) -> String {
        formatter().string(from: date)
    }

    public static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return formatter().date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
