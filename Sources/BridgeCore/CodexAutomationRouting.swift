import Foundation

public struct CodexAutomationRunResult: Equatable, Sendable {
    public var automationId: String
    public var sessionId: String
    public var completedAt: String?
    public var message: String
    public var path: String

    public init(automationId: String, sessionId: String, completedAt: String?, message: String, path: String) {
        self.automationId = automationId
        self.sessionId = sessionId
        self.completedAt = completedAt
        self.message = message
        self.path = path
    }
}

public struct CodexAutomationScanOptions: Equatable, Sendable {
    public var sessionIdLowerBound: String?
    public var maximumFilesToRead: Int?

    public init(sessionIdLowerBound: String? = nil, maximumFilesToRead: Int? = nil) {
        self.sessionIdLowerBound = sessionIdLowerBound
        self.maximumFilesToRead = maximumFilesToRead
    }
}

public struct CodexAutomationScanResult: Equatable, Sendable {
    public var runs: [CodexAutomationRunResult]
    public var candidateFileCount: Int
    public var skippedFileCount: Int
    public var readFileCount: Int

    public init(runs: [CodexAutomationRunResult], candidateFileCount: Int, skippedFileCount: Int, readFileCount: Int) {
        self.runs = runs
        self.candidateFileCount = candidateFileCount
        self.skippedFileCount = skippedFileCount
        self.readFileCount = readFileCount
    }
}

public func upsertCodexAutomationRoute(_ route: CodexAutomationRoute, into routes: [CodexAutomationRoute]) -> [CodexAutomationRoute] {
    var updated = routes
    if let index = updated.firstIndex(where: { $0.automationId == route.automationId }) {
        var existing = updated[index]
        existing.name = route.name
        existing.recipient = route.recipient
        existing.service = route.service
        existing.createdFromGuid = route.createdFromGuid
        existing.createdFromRowId = route.createdFromRowId
        existing.createdAt = route.createdAt
        updated[index] = existing
    } else {
        updated.append(route)
    }
    return updated.sorted { $0.automationId < $1.automationId }
}

public func sanitizedAutomationMessage(_ text: String) -> String {
    let withoutDirectives = text
        .components(separatedBy: .newlines)
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("::") }
        .joined(separator: "\n")
    return withoutDirectives.trimmingCharacters(in: .whitespacesAndNewlines)
}

public func completedCodexAutomationRuns(in sessionsDir: URL, routes: [CodexAutomationRoute]) -> [CodexAutomationRunResult] {
    completedCodexAutomationRunScan(in: sessionsDir, routes: routes).runs
}

public func completedCodexAutomationRunScan(in sessionsDir: URL, routes: [CodexAutomationRoute], options: CodexAutomationScanOptions? = nil) -> CodexAutomationScanResult {
    let routeIds = Set(routes.map(\.automationId))
    guard !routeIds.isEmpty else {
        return CodexAutomationScanResult(runs: [], candidateFileCount: 0, skippedFileCount: 0, readFileCount: 0)
    }
    var scanOptions = options ?? CodexAutomationScanOptions()
    if scanOptions.sessionIdLowerBound == nil {
        scanOptions.sessionIdLowerBound = sessionIdLowerBound(from: routes)
    }
    let files = codexSessionFiles(in: sessionsDir)
    var skippedFileCount = 0
    var readFileCount = 0
    var runs: [CodexAutomationRunResult] = []
    for file in files {
        if let sessionIdLowerBound = scanOptions.sessionIdLowerBound,
           let sessionId = rolloutSessionId(from: file),
           sessionId <= sessionIdLowerBound {
            skippedFileCount += 1
            continue
        }
        if let maximumFilesToRead = scanOptions.maximumFilesToRead, readFileCount >= maximumFilesToRead {
            skippedFileCount += 1
            continue
        }
        readFileCount += 1
        if let run = completedCodexAutomationRun(in: file, routeIds: routeIds) {
            runs.append(run)
        }
    }
    return CodexAutomationScanResult(
        runs: runs.sorted { $0.completedAt ?? "" < $1.completedAt ?? "" },
        candidateFileCount: files.count,
        skippedFileCount: skippedFileCount,
        readFileCount: readFileCount
    )
}

public func completedCodexAutomationRun(in file: URL, routeIds: Set<String>) -> CodexAutomationRunResult? {
    guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
    defer { try? handle.close() }

    var automationId: String?
    var sessionId: String?
    var completedAt: String?
    var finalMessage: String?

    let data = handle.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
        guard let object = jsonObject(from: String(line)) else { continue }
        let type = object["type"] as? String
        let timestamp = object["timestamp"] as? String
        let payload = object["payload"] as? [String: Any]
        if type == "session_meta" {
            sessionId = payload?["id"] as? String ?? sessionId
            continue
        }
        if automationId == nil {
            let candidate = automationIdInObject(object, routeIds: routeIds)
            if let candidate {
                automationId = candidate
            }
        }
        if (type == "task_complete" || (type == "event_msg" && payload?["type"] as? String == "task_complete")), let payload {
            finalMessage = payload["last_agent_message"] as? String ?? finalMessage
            completedAt = timestamp ?? completedAt
        }
    }

    guard let automationId, let sessionId, routeIds.contains(automationId), let finalMessage else { return nil }
    let cleaned = sanitizedAutomationMessage(finalMessage)
    guard !cleaned.isEmpty else { return nil }
    return CodexAutomationRunResult(automationId: automationId, sessionId: sessionId, completedAt: completedAt, message: cleaned, path: file.path)
}

public func automationMetadata(at url: URL) -> (id: String, name: String, createdAt: String?)? {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    let values = tomlScalarValues(from: text)
    guard let id = values["id"], let name = values["name"] else { return nil }
    let createdAt: String?
    if let milliseconds = values["created_at"], let value = TimeInterval(milliseconds) {
        createdAt = DateCodec.iso(Date(timeIntervalSince1970: value / 1000))
    } else {
        createdAt = nil
    }
    return (id, name, createdAt)
}

private func codexSessionFiles(in sessionsDir: URL) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
        at: sessionsDir,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    ) else { return [] }
    var files: [URL] = []
    for case let file as URL in enumerator where file.pathExtension == "jsonl" && file.lastPathComponent.hasPrefix("rollout-") {
        files.append(file)
    }
    return files.sorted {
        let left = rolloutSessionId(from: $0) ?? $0.path
        let right = rolloutSessionId(from: $1) ?? $1.path
        return left < right
    }
}

private func sessionIdLowerBound(from routes: [CodexAutomationRoute]) -> String? {
    let deliveredSessionIds = routes.compactMap(\.lastDeliveredSessionId)
    guard deliveredSessionIds.count == routes.count else { return nil }
    return deliveredSessionIds.min()
}

private func rolloutSessionId(from file: URL) -> String? {
    let basename = file.deletingPathExtension().lastPathComponent
    guard basename.hasPrefix("rollout-") else { return nil }
    let tail = basename.dropFirst("rollout-".count)
    guard tail.count >= 36 else { return nil }
    let candidate = String(tail.suffix(36))
    let pattern = #"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"#
    return candidate.range(of: pattern, options: .regularExpression) == nil ? nil : candidate.lowercased()
}

private func jsonObject(from line: String) -> [String: Any]? {
    guard let data = line.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
}

private func automationIdInObject(_ value: Any, routeIds: Set<String>) -> String? {
    if let string = value as? String {
        return automationId(in: string, routeIds: routeIds)
    }
    if let array = value as? [Any] {
        for item in array {
            if let id = automationIdInObject(item, routeIds: routeIds) { return id }
        }
    }
    if let object = value as? [String: Any] {
        for item in object.values {
            if let id = automationIdInObject(item, routeIds: routeIds) { return id }
        }
    }
    return nil
}

private func automationId(in text: String, routeIds: Set<String>) -> String? {
    for line in text.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("automation id:") else { continue }
        let id = trimmed.dropFirst("automation id:".count).trimmingCharacters(in: .whitespacesAndNewlines)
        if routeIds.contains(id) { return id }
    }
    return nil
}

private func tomlScalarValues(from text: String) -> [String: String] {
    var values: [String: String] = [:]
    for rawLine in text.components(separatedBy: .newlines) {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty, !line.hasPrefix("#"), let equal = line.firstIndex(of: "=") else { continue }
        let key = line[..<equal].trimmingCharacters(in: .whitespacesAndNewlines)
        var value = line[line.index(after: equal)...].trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            value.removeFirst()
            value.removeLast()
        }
        values[key] = value
    }
    return values
}
