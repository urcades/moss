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

public struct CodexAutomationForwardingResult: Equatable, Sendable {
    public var scan: CodexAutomationScanResult
    public var forwardedCount: Int

    public init(scan: CodexAutomationScanResult, forwardedCount: Int) {
        self.scan = scan
        self.forwardedCount = forwardedCount
    }
}

public struct CodexAutomationFileSummary: Equatable, Sendable {
    public var id: String
    public var name: String
    public var status: String
    public var path: String

    public init(id: String, name: String, status: String, path: String) {
        self.id = id
        self.name = name
        self.status = status
        self.path = path
    }
}

public struct BridgeSmokeAutomationCleanupResult: Equatable, Sendable {
    public var dryRun: Bool
    public var targets: [CodexAutomationFileSummary]
    public var changedPaths: [String]

    public init(dryRun: Bool, targets: [CodexAutomationFileSummary], changedPaths: [String]) {
        self.dryRun = dryRun
        self.targets = targets
        self.changedPaths = changedPaths
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

@discardableResult
public func forwardCompletedAutomationRunsOnce(
    paths: RuntimePaths,
    stores: RuntimeStores,
    replySink: any ReplySink,
    now: Date = Date(),
    maximumFilesToRead: Int? = 25
) async throws -> CodexAutomationForwardingResult {
    let initialState = try stores.state.load()
    let routes = initialState.automationRoutes ?? []
    let scan = completedCodexAutomationRunScan(
        in: paths.codexSessionsDir,
        routes: routes,
        options: CodexAutomationScanOptions(maximumFilesToRead: maximumFilesToRead)
    )
    guard !scan.runs.isEmpty else {
        return CodexAutomationForwardingResult(scan: scan, forwardedCount: 0)
    }

    let latestRuns = Dictionary(scan.runs.map { ($0.automationId, $0) }, uniquingKeysWith: { _, latest in latest })
    var forwardedCount = 0
    for run in latestRuns.values.sorted(by: { $0.automationId < $1.automationId }) {
        let currentState = try stores.state.load()
        guard let route = currentState.automationRoutes?.first(where: { $0.automationId == run.automationId }) else { continue }
        guard route.lastDeliveredSessionId != run.sessionId else { continue }
        _ = try await replySink.sendReply(recipient: route.recipient, service: route.service, text: run.message)
        let deliveredAt = run.completedAt ?? DateCodec.iso(now)
        try stores.state.update { state in
            state.markAutomationRouteDelivered(automationId: run.automationId, sessionId: run.sessionId, deliveredAt: deliveredAt)
        }
        forwardedCount += 1
    }

    return CodexAutomationForwardingResult(scan: scan, forwardedCount: forwardedCount)
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
    var filesToRead: [URL] = []
    var skippedFileCount = 0
    for file in files {
        if let sessionIdLowerBound = scanOptions.sessionIdLowerBound,
           let sessionId = rolloutSessionId(from: file),
           sessionId < sessionIdLowerBound {
            skippedFileCount += 1
            continue
        }
        filesToRead.append(file)
    }
    if let maximumFilesToRead = scanOptions.maximumFilesToRead, filesToRead.count > maximumFilesToRead {
        skippedFileCount += filesToRead.count - maximumFilesToRead
        filesToRead = Array(filesToRead.suffix(maximumFilesToRead))
    }

    var runs: [CodexAutomationRunResult] = []
    for file in filesToRead {
        if let run = completedCodexAutomationRun(in: file, routeIds: routeIds) {
            runs.append(run)
        }
    }
    return CodexAutomationScanResult(
        runs: runs.sorted { $0.completedAt ?? "" < $1.completedAt ?? "" },
        candidateFileCount: files.count,
        skippedFileCount: skippedFileCount,
        readFileCount: filesToRead.count
    )
}

public func completedCodexAutomationRun(in file: URL, routeIds: Set<String>) -> CodexAutomationRunResult? {
    guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
    defer { try? handle.close() }

    var sessionId: String?
    var pendingAutomationId: String?
    var runs: [CodexAutomationRunResult] = []

    let data = handle.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
        guard let object = jsonObject(from: String(line)) else { continue }
        let type = object["type"] as? String
        let payload = object["payload"] as? [String: Any]
        if type == "session_meta" {
            sessionId = payload?["id"] as? String ?? sessionId
            continue
        }
        if isCodexUserMessageObject(object) {
            pendingAutomationId = automationIdInUserMessageObject(object, routeIds: routeIds)
            continue
        }
        guard let taskPayload = taskCompletePayload(in: object),
              let automationId = pendingAutomationId,
              let sessionId else {
            continue
        }
        pendingAutomationId = nil
        guard let finalMessage = taskPayload["last_agent_message"] as? String else { continue }
        let cleaned = sanitizedAutomationMessage(finalMessage)
        guard !cleaned.isEmpty else { continue }
        let runSessionId: String
        if let turnId = taskPayload["turn_id"] as? String, !turnId.isEmpty {
            runSessionId = "\(sessionId)#\(turnId)"
        } else {
            runSessionId = sessionId
        }
        runs.append(CodexAutomationRunResult(
            automationId: automationId,
            sessionId: runSessionId,
            completedAt: object["timestamp"] as? String,
            message: cleaned,
            path: file.path
        ))
    }

    return runs.sorted { $0.completedAt ?? "" < $1.completedAt ?? "" }.last
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

public func activeBridgeSmokeAutomations(in automationsDir: URL) -> [CodexAutomationFileSummary] {
    automationFileSummaries(in: automationsDir)
        .filter { summary in
            isBridgeSmokeAutomation(summary) && summary.status != "INACTIVE"
        }
        .sorted { lhs, rhs in
            if lhs.id == rhs.id { return lhs.path < rhs.path }
            return lhs.id < rhs.id
        }
}

public func bridgeSmokeAutomationStatusText(_ summaries: [CodexAutomationFileSummary]) -> String {
    guard !summaries.isEmpty else {
        return "No active bridge smoke automations found."
    }
    let detail = summaries.prefix(8).map { summary in
        "\(summary.id) status \(summary.status) path \(summary.path)"
    }.joined(separator: "; ")
    let suffix = summaries.count > 8 ? "; ... \(summaries.count - 8) more" : ""
    return "warning: \(summaries.count) active bridge smoke automation(s): \(detail)\(suffix)"
}

public func deactivateActiveBridgeSmokeAutomations(in automationsDir: URL, dryRun: Bool) throws -> BridgeSmokeAutomationCleanupResult {
    let targets = activeBridgeSmokeAutomations(in: automationsDir)
    guard !dryRun else {
        return BridgeSmokeAutomationCleanupResult(dryRun: true, targets: targets, changedPaths: [])
    }
    var changedPaths: [String] = []
    for target in targets {
        let file = URL(fileURLWithPath: target.path)
        let text = try String(contentsOf: file, encoding: .utf8)
        let updated = automationTomlSettingStatusInactive(text)
        if updated != text {
            try updated.data(using: .utf8)?.write(to: file, options: .atomic)
            changedPaths.append(target.path)
        }
    }
    return BridgeSmokeAutomationCleanupResult(dryRun: false, targets: targets, changedPaths: changedPaths)
}

public func bridgeSmokeAutomationCleanupStatusText(_ result: BridgeSmokeAutomationCleanupResult) -> String {
    guard !result.targets.isEmpty else {
        return "No active bridge smoke automations found."
    }
    let ids = result.targets.map(\.id).joined(separator: ", ")
    if result.dryRun {
        return "Dry run: would mark \(result.targets.count) active bridge smoke automation(s) inactive: \(ids)"
    }
    return "Marked \(result.changedPaths.count)/\(result.targets.count) active bridge smoke automation(s) inactive: \(ids)"
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

private func automationFileSummaries(in automationsDir: URL) -> [CodexAutomationFileSummary] {
    guard let entries = try? FileManager.default.contentsOfDirectory(
        at: automationsDir,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
    ) else { return [] }
    return entries.compactMap { entry in
        let file = entry.appendingPathComponent("automation.toml")
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { return nil }
        let values = tomlScalarValues(from: text)
        guard let id = values["id"], let name = values["name"] else { return nil }
        let status = (values["status"] ?? "ACTIVE")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return CodexAutomationFileSummary(id: id, name: name, status: status.isEmpty ? "ACTIVE" : status, path: file.path)
    }
}

private func isBridgeSmokeAutomation(_ summary: CodexAutomationFileSummary) -> Bool {
    summary.id.hasPrefix("bridge-smoke-test") ||
        summary.name.localizedCaseInsensitiveContains("Bridge Smoke Test")
}

private func automationTomlSettingStatusInactive(_ text: String) -> String {
    var replaced = false
    var lines = text.components(separatedBy: .newlines).map { line -> String in
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("status"), let equals = line.firstIndex(of: "=") else {
            return line
        }
        replaced = true
        let prefix = line[..<equals].trimmingCharacters(in: .whitespaces)
        let leading = line.prefix { $0 == " " || $0 == "\t" }
        return "\(leading)\(prefix) = \"INACTIVE\""
    }
    if !replaced {
        if lines.last == "" {
            lines.insert(#"status = "INACTIVE""#, at: max(0, lines.count - 1))
        } else {
            lines.append(#"status = "INACTIVE""#)
        }
    }
    return lines.joined(separator: "\n")
}

private func sessionIdLowerBound(from routes: [CodexAutomationRoute]) -> String? {
    let deliveredSessionIds = routes.compactMap(\.lastDeliveredSessionId).map(baseSessionId)
    guard deliveredSessionIds.count == routes.count else { return nil }
    return deliveredSessionIds.min()
}

private func baseSessionId(_ deliveryId: String) -> String {
    String(deliveryId.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first ?? Substring(deliveryId))
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

private func isCodexUserMessageObject(_ object: [String: Any]) -> Bool {
    let type = object["type"] as? String
    let payload = object["payload"] as? [String: Any]
    if type == "event_msg", payload?["type"] as? String == "user_message" {
        return true
    }
    return type == "response_item" &&
        payload?["type"] as? String == "message" &&
        payload?["role"] as? String == "user"
}

private func automationIdInUserMessageObject(_ object: [String: Any], routeIds: Set<String>) -> String? {
    let payload = object["payload"] as? [String: Any]
    if object["type"] as? String == "event_msg" {
        return automationIdInObject(payload?["message"] ?? "", routeIds: routeIds)
    }
    return automationIdInObject(payload?["content"] ?? "", routeIds: routeIds)
}

private func taskCompletePayload(in object: [String: Any]) -> [String: Any]? {
    let type = object["type"] as? String
    let payload = object["payload"] as? [String: Any]
    if type == "task_complete" {
        return payload
    }
    if type == "event_msg", payload?["type"] as? String == "task_complete" {
        return payload
    }
    return nil
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
