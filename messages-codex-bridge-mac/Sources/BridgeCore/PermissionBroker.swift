import Foundation

public struct PermissionPromptSnapshot: Equatable, Sendable {
    public var ownerName: String
    public var ownerBundleId: String?
    public var windowTitle: String
    public var promptText: String
    public var buttonLabels: [String]

    public init(ownerName: String, ownerBundleId: String?, windowTitle: String, promptText: String, buttonLabels: [String]) {
        self.ownerName = ownerName
        self.ownerBundleId = ownerBundleId
        self.windowTitle = windowTitle
        self.promptText = promptText
        self.buttonLabels = buttonLabels
    }
}

public struct PermissionBrokerDecision: Equatable, Sendable {
    public var shouldClick: Bool
    public var buttonLabel: String?
    public var requesterMatched: String?
    public var reason: String
}

public func permissionBrokerDecision(for prompt: PermissionPromptSnapshot, config: PermissionBrokerConfig) -> PermissionBrokerDecision {
    guard config.enabled else {
        return PermissionBrokerDecision(shouldClick: false, buttonLabel: nil, requesterMatched: nil, reason: "broker disabled")
    }

    let combined = [
        prompt.ownerName,
        prompt.ownerBundleId ?? "",
        prompt.windowTitle,
        prompt.promptText
    ].joined(separator: "\n")
    let requester = config.trustedRequesters.first { combined.localizedCaseInsensitiveContains($0) }
    guard requester != nil else {
        return PermissionBrokerDecision(shouldClick: false, buttonLabel: nil, requesterMatched: requester, reason: "not a trusted permission prompt")
    }

    let ignored = Set(config.ignoredButtonLabels.map { $0.lowercased() })
    let available = prompt.buttonLabels.filter { !ignored.contains($0.lowercased()) }
    guard let positive = config.positiveButtonLabels.first(where: { label in
        available.contains { $0.caseInsensitiveCompare(label) == .orderedSame }
    }) else {
        return PermissionBrokerDecision(shouldClick: false, buttonLabel: nil, requesterMatched: requester, reason: "no positive button found")
    }
    return PermissionBrokerDecision(shouldClick: true, buttonLabel: positive, requesterMatched: requester, reason: "trusted prompt")
}

public func looksLikePermissionPrompt(_ text: String) -> Bool {
    let markers = [
        "would like to",
        "wants to",
        "allow",
        "access",
        "control",
        "automation",
        "privacy",
        "screen recording",
        "accessibility",
        "contacts",
        "files",
        "folder",
        "microphone",
        "camera"
    ]
    return markers.contains { text.localizedCaseInsensitiveContains($0) }
}

public func isRecoverablePermissionBlock(_ text: String) -> Bool {
    let markers = [
        "Apple event error -1743",
        "Apple event error -10000",
        "Sender process is not authenticated",
        "Computer Use permission request canceled",
        "not authorized to send Apple events",
        "operation not permitted",
        "Allow remote automation",
        "grant ",
        "Accessibility",
        "Screen Recording",
        "Full Disk Access"
    ]
    return markers.contains { text.localizedCaseInsensitiveContains($0) }
}

public func writePermissionBrokerStatus(_ status: PermissionBrokerStatus, paths: RuntimePaths) throws {
    try FileManager.default.createDirectory(at: paths.permissionBrokerDir, withIntermediateDirectories: true)
    let data = try JSONEncoder.pretty.encode(status)
    try data.write(to: paths.permissionBrokerStatusPath, options: .atomic)
}

public func readPermissionBrokerStatus(paths: RuntimePaths) -> PermissionBrokerStatus? {
    guard FileManager.default.fileExists(atPath: paths.permissionBrokerStatusPath.path),
          let data = try? Data(contentsOf: paths.permissionBrokerStatusPath) else { return nil }
    return try? JSONDecoder().decode(PermissionBrokerStatus.self, from: data)
}

public func appendPermissionBrokerEvent(_ event: PermissionBrokerEvent, paths: RuntimePaths) throws {
    try FileManager.default.createDirectory(at: paths.permissionBrokerDir, withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(event)
    var line = String(data: data, encoding: .utf8) ?? "{}"
    line += "\n"
    if FileManager.default.fileExists(atPath: paths.permissionBrokerEventsPath.path),
       let handle = try? FileHandle(forWritingTo: paths.permissionBrokerEventsPath) {
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(line.utf8))
        try handle.close()
    } else {
        try Data(line.utf8).write(to: paths.permissionBrokerEventsPath, options: .atomic)
    }
}

public func recentPermissionBrokerEvents(paths: RuntimePaths, limit: Int = 20) -> [PermissionBrokerEvent] {
    guard FileManager.default.fileExists(atPath: paths.permissionBrokerEventsPath.path),
          let text = try? String(contentsOf: paths.permissionBrokerEventsPath, encoding: .utf8) else { return [] }
    return text
        .components(separatedBy: .newlines)
        .suffix(limit * 3)
        .compactMap { line -> PermissionBrokerEvent? in
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let data = line.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(PermissionBrokerEvent.self, from: data)
        }
        .suffix(limit)
}

public func permissionPromptFingerprint(_ prompt: PermissionPromptSnapshot, buttonLabel: String?) -> String {
    [
        prompt.ownerName,
        prompt.ownerBundleId ?? "",
        prompt.windowTitle,
        prompt.promptText,
        buttonLabel ?? ""
    ].joined(separator: "|")
}
