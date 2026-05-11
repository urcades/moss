import Foundation

public enum StoreError: Error, CustomStringConvertible {
    case validation(String)

    public var description: String {
        switch self {
        case .validation(let message): message
        }
    }
}

public func ensureRuntimeDirectories(_ paths: RuntimePaths) throws {
    for url in [paths.appSupportDir, paths.stateDir, paths.tmpDir, paths.logsDir, paths.permissionBrokerDir] {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

public func defaultBridgeConfig(paths: RuntimePaths, codexCommand: String? = nil) -> BridgeConfig {
    BridgeConfig(
        allowedSender: BridgeConstants.defaultAllowedSender,
        trustedSenders: nil,
        pollIntervalMs: BridgeConstants.defaultPollIntervalMs,
        batchWindowMs: BridgeConstants.defaultBatchWindowMs,
        chunkSize: BridgeConstants.defaultChunkSize,
        ackDelayMs: BridgeConstants.defaultAckDelayMs,
        timeoutMs: BridgeConstants.defaultTimeoutMs,
        sessionTtlMs: BridgeConstants.defaultSessionTtlMs,
        homeAccessRoot: paths.homeDir.path,
        messagesDbPath: paths.defaultMessagesDbPath.path,
        osascriptCommand: "/usr/bin/osascript",
        codex: CodexConfig(
            command: codexCommand ?? "/Applications/Codex.app/Contents/Resources/codex",
            cwd: paths.defaultCodexCwd.path,
            model: "gpt-5.4",
            reasoningEffort: "xhigh",
            stylePrompt: BridgeConstants.defaultStylePrompt,
            extraArgs: []
        ),
        outgoingAttachmentMode: "fullAccess",
        outgoingAttachmentRoots: ["/"],
        outgoingAttachmentExtensions: ["*"],
        longTaskProgressIntervalMs: BridgeConstants.defaultLongTaskProgressIntervalMs,
        longTaskMilestoneMinIntervalMs: BridgeConstants.defaultLongTaskMilestoneMinIntervalMs,
        activeJobAckEnabled: true,
        activeJobAckText: BridgeConstants.defaultActiveJobAckText,
        permissionBroker: defaultPermissionBrokerConfig()
    )
}

public func defaultOutgoingAttachmentExtensions() -> [String] {
    ["png", "jpg", "jpeg", "gif", "heic", "tif", "tiff", "bmp", "webp", "pdf"]
}

public func defaultPermissionBrokerConfig() -> PermissionBrokerConfig {
    PermissionBrokerConfig(
        enabled: true,
        mode: "broadAuto",
        scanIntervalMs: BridgeConstants.defaultPermissionBrokerScanIntervalMs,
        recoveryTimeoutMs: BridgeConstants.defaultPermissionBrokerRecoveryTimeoutMs,
        maxRecoveryAttempts: BridgeConstants.defaultPermissionBrokerMaxRecoveryAttempts,
        trustedRequesters: [
            "Codex",
            "Computer Use",
            "CUAService",
            "OpenAI",
            "com.openai.codex",
            "com.openai.sky.CUAService",
            BridgeConstants.appBundleIdentifier,
            BridgeConstants.helperBundleIdentifier,
            BridgeConstants.permissionBrokerBundleIdentifier,
            "Messages Codex Bridge",
            "Messages Codex Bridge Helper",
            "Messages Codex Permission Broker"
        ],
        trustedPromptOwners: [
            "SecurityAgent",
            "CoreServicesUIAgent",
            "UserNotificationCenter",
            "System Settings",
            "SystemUIServer",
            "Messages",
            "Contacts",
            "Safari",
            "Codex"
        ],
        positiveButtonLabels: ["Allow", "OK", "Continue", "Always Allow", "Open System Settings"],
        ignoredButtonLabels: ["Don't Allow", "Don’t Allow", "Deny", "Cancel", "Not Now", "Later"]
    )
}

public func defaultBridgeState() -> BridgeState {
    BridgeState(
        lastProcessedGuid: nil,
        lastProcessedRowId: 0,
        pendingBatch: nil,
        activeJob: nil,
        codexSession: CodexSessionState()
    )
}

public func validateConfig(_ config: BridgeConfig) throws {
    for (name, value) in [
        ("pollIntervalMs", config.pollIntervalMs),
        ("batchWindowMs", config.batchWindowMs),
        ("chunkSize", config.chunkSize),
        ("timeoutMs", config.timeoutMs),
        ("sessionTtlMs", config.sessionTtlMs),
        ("longTaskProgressIntervalMs", config.effectiveLongTaskProgressIntervalMs),
        ("longTaskMilestoneMinIntervalMs", config.effectiveLongTaskMilestoneMinIntervalMs),
        ("permissionBroker.scanIntervalMs", config.effectivePermissionBroker.scanIntervalMs),
        ("permissionBroker.recoveryTimeoutMs", config.effectivePermissionBroker.recoveryTimeoutMs),
        ("permissionBroker.maxRecoveryAttempts", config.effectivePermissionBroker.maxRecoveryAttempts)
    ] where value <= 0 {
        throw StoreError.validation("Config field \(name) must be positive.")
    }
    if config.ackDelayMs < 0 { throw StoreError.validation("Config field ackDelayMs must be zero or positive.") }
    if config.messagesDbPath.isEmpty { throw StoreError.validation("Config field messagesDbPath is required.") }
    if config.codex.command.isEmpty { throw StoreError.validation("Config.codex.command is required.") }
    if config.codex.cwd.isEmpty { throw StoreError.validation("Config.codex.cwd is required.") }
}

public extension BridgeConfig {
    var effectiveTrustedSenders: [String] {
        let trusted = normalizedTrustedSenderList(trustedSenders ?? [])
        if !trusted.isEmpty { return trusted }
        return normalizedTrustedSenderList([allowedSender])
    }

    var effectiveLongTaskProgressIntervalMs: Int { longTaskProgressIntervalMs ?? BridgeConstants.defaultLongTaskProgressIntervalMs }
    var effectiveLongTaskMilestoneMinIntervalMs: Int { longTaskMilestoneMinIntervalMs ?? BridgeConstants.defaultLongTaskMilestoneMinIntervalMs }
    var effectiveActiveJobAckEnabled: Bool { activeJobAckEnabled ?? true }
    var effectiveActiveJobAckText: String { activeJobAckText ?? BridgeConstants.defaultActiveJobAckText }
    var effectivePermissionBroker: PermissionBrokerConfig { permissionBroker ?? defaultPermissionBrokerConfig() }
    var effectiveOutgoingAttachmentMode: String { outgoingAttachmentMode ?? "fullAccess" }
    var effectiveOutgoingAttachmentRoots: [String] {
        outgoingAttachmentRoots ?? ["/"]
    }
    var effectiveOutgoingAttachmentExtensions: [String] { outgoingAttachmentExtensions ?? ["*"] }

    mutating func syncTrustedSenders(_ senders: [String]) {
        let normalized = normalizedTrustedSenderList(senders)
        trustedSenders = normalized
        allowedSender = normalized.first ?? ""
    }
}

public func normalizedTrustedSenderList(_ senders: [String]) -> [String] {
    var identities = Set<String>()
    var results: [String] = []
    for sender in senders {
        let trimmed = sender.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }
        let identity = normalizedTrustedSenderIdentity(trimmed)
        guard !identity.isEmpty, identities.insert(identity).inserted else { continue }
        results.append(trimmed)
    }
    return results
}

public final class JSONFileStore<Value: Codable> {
    private let url: URL
    private let defaultValue: () -> Value

    public init(url: URL, defaultValue: @escaping () -> Value) {
        self.url = url
        self.defaultValue = defaultValue
    }

    public func load() throws -> Value {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return defaultValue()
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Value.self, from: data)
    }

    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.pretty.encode(value)
        let tmp = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }

    public func ensureExists() throws -> Value {
        let value = try load()
        try save(value)
        return value
    }
}

public extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

public final class RuntimeStores {
    public let paths: RuntimePaths
    public let config: JSONFileStore<BridgeConfig>
    public let state: JSONFileStore<BridgeState>

    public init(paths: RuntimePaths) {
        self.paths = paths
        self.config = JSONFileStore(url: paths.configPath) { defaultBridgeConfig(paths: paths) }
        self.state = JSONFileStore(url: paths.statePath) { defaultBridgeState() }
    }
}
