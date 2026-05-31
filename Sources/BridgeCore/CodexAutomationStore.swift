import Foundation

public struct CreatedCodexAutomation: Equatable, Sendable {
    public var id: String
    public var name: String
    public var rrule: String
    public var path: String
}

public struct CodexAutomationSpec: Equatable, Sendable {
    public var name: String
    public var prompt: String
    public var rrule: String
    public var model: String?
    public var reasoningEffort: String?
    public var executionEnvironment: String?
    public var cwds: [String]?
    public var status: String

    public init(name: String, prompt: String, rrule: String, model: String? = nil, reasoningEffort: String? = nil, executionEnvironment: String? = nil, cwds: [String]? = nil, status: String = "ACTIVE") {
        self.name = name
        self.prompt = prompt
        self.rrule = rrule
        self.model = model
        self.reasoningEffort = reasoningEffort
        self.executionEnvironment = executionEnvironment
        self.cwds = cwds
        self.status = status
    }
}

public struct CodexAutomationSmokeResult: Equatable, Sendable {
    public var marker: String
    public var automation: CreatedCodexAutomation
    public var route: CodexAutomationRoute

    public init(marker: String, automation: CreatedCodexAutomation, route: CodexAutomationRoute) {
        self.marker = marker
        self.automation = automation
        self.route = route
    }
}

public func createCodexAutomationSmoke(
    recipient: String,
    service: String,
    config: BridgeConfig,
    paths: RuntimePaths,
    stores: RuntimeStores,
    now: Date = Date(),
    marker: String = "CODEXMSGCTL_SMOKE_AUTOMATION_\(UUID().uuidString)"
) throws -> CodexAutomationSmokeResult {
    let shortMarker = String(marker.suffix(8))
    let nowText = DateCodec.iso(now)
    let name = "Bridge Smoke Test \(shortMarker)"
    let spec = CodexAutomationSpec(
        name: name,
        prompt: "Return exactly this text and nothing else: \(marker)",
        rrule: "FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=31;BYHOUR=23;BYMINUTE=59;BYSECOND=0",
        model: config.codex.model ?? "gpt-5.2",
        reasoningEffort: config.codex.reasoningEffort,
        executionEnvironment: "local",
        cwds: [config.codex.cwd],
        status: "INACTIVE"
    )
    let batch = PendingBatch(
        handleId: recipient,
        service: service,
        startedAt: nowText,
        deadlineAt: nowText,
        items: [
            MessageItem(
                rowId: 0,
                guid: "codexmsgctl-smoke-\(marker)",
                text: "Create a new automation that returns \(marker).",
                handleId: recipient,
                service: service,
                receivedAt: nowText,
                attachments: []
            )
        ]
    )
    guard let automation = try createCodexAutomationIfRequested(batch: batch, config: config, paths: paths, now: now, spec: spec) else {
        throw StoreError.validation("Smoke automation failed: creation helper returned nil.")
    }
    guard let metadata = automationMetadata(at: URL(fileURLWithPath: automation.path)),
          metadata.id == automation.id,
          metadata.name == automation.name else {
        throw StoreError.validation("Smoke automation failed: created TOML metadata did not match \(automation.path).")
    }
    let route = CodexAutomationRoute(
        automationId: automation.id,
        name: automation.name,
        recipient: recipient,
        service: service,
        createdFromGuid: "codexmsgctl-smoke-\(marker)",
        createdFromRowId: nil,
        createdAt: nowText
    )
    var state = try stores.state.load()
    state.automationRoutes = upsertCodexAutomationRoute(route, into: state.automationRoutes ?? [])
    state.automationCreationStatus = AutomationCreationStatus(
        automationId: automation.id,
        name: automation.name,
        sourceRowId: nil,
        sourceGuid: "codexmsgctl-smoke-\(marker)",
        phase: "confirmed",
        createdFilePath: automation.path,
        routeStatus: "route persisted",
        confirmationSendStatus: "codexmsgctl smoke verified",
        updatedAt: nowText
    )
    try stores.state.save(state)
    let reloaded = try stores.state.load()
    guard reloaded.automationRoutes?.contains(where: { $0.automationId == automation.id && $0.recipient == recipient && $0.service == service }) == true else {
        throw StoreError.validation("Smoke automation failed: route was not persisted in bridge state.")
    }
    return CodexAutomationSmokeResult(marker: marker, automation: automation, route: route)
}

public func createCodexAutomationIfRequested(batch: PendingBatch, config: BridgeConfig, paths: RuntimePaths, now: Date = Date(), spec: CodexAutomationSpec? = nil) throws -> CreatedCodexAutomation? {
    let messageText = batch.items.map(\.text).joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    guard shouldCreateCodexAutomation(from: messageText) else { return nil }
    let draft = spec.map { codexAutomationDraft(from: $0, config: config) } ?? codexAutomationDraft(from: messageText, config: config)
    return try writeCodexAutomation(draft, paths: paths, now: now)
}

public func shouldCreateCodexAutomation(from text: String) -> Bool {
    guard promptLooksLikeCodexAutomationRequest(text) else { return false }
    let normalized = canonicalPromptText(text)
    let managementPhrases = [
        "delete automation",
        "delete automations",
        "remove automation",
        "remove automations",
        "list automation",
        "list automations",
        "show automation",
        "show automations",
        "view automation",
        "view automations",
        "automation status",
        "automation statuses",
        "status of automation",
        "status of automations",
        "why did automation",
        "why did the automation",
        "why didnt automation",
        "why didnt the automation",
        "automation failed",
        "automation error",
        "debug automation",
        "diagnose automation",
        "inspect automation",
        "look into automation",
        "look into the automation"
    ]
    if managementPhrases.contains(where: { containsPhrase(normalized, $0) }) {
        return false
    }
    return automationCreationIntentScore(text) > 0
}

private struct CodexAutomationDraft {
    var name: String
    var prompt: String
    var rrule: String
    var model: String
    var reasoningEffort: String?
    var executionEnvironment: String
    var cwds: [String]
    var status: String
}

private func codexAutomationDraft(from text: String, config: BridgeConfig) -> CodexAutomationDraft {
    CodexAutomationDraft(
        name: automationName(from: text),
        prompt: automationPrompt(from: text),
        rrule: automationRRule(from: text, includeSeconds: false),
        model: config.codex.model ?? "gpt-5.2",
        reasoningEffort: config.codex.reasoningEffort,
        executionEnvironment: "local",
        cwds: ["~"],
        status: "ACTIVE"
    )
}

private func codexAutomationDraft(from spec: CodexAutomationSpec, config: BridgeConfig) -> CodexAutomationDraft {
    CodexAutomationDraft(
        name: automationTitle(spec.name, limit: 80),
        prompt: spec.prompt.trimmingCharacters(in: .whitespacesAndNewlines),
        rrule: normalizedRRule(spec.rrule),
        model: spec.model?.nilIfBlank ?? config.codex.model ?? "gpt-5.2",
        reasoningEffort: spec.reasoningEffort?.nilIfBlank ?? config.codex.reasoningEffort,
        executionEnvironment: spec.executionEnvironment == "worktree" ? "worktree" : "local",
        cwds: spec.cwds?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? [config.codex.cwd],
        status: normalizedAutomationStatus(spec.status)
    )
}

private func automationName(from text: String) -> String {
    let normalized = text.lowercased()
    if normalized.contains("morning digest") {
        return "Morning Digest"
    }
    if normalized.contains("daily digest") {
        return "Daily Digest"
    }
    let firstLine = text
        .split(whereSeparator: \.isNewline)
        .map(String.init)
        .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Codex Automation"
    let cleaned = firstLine
        .replacingOccurrences(of: #"(?i)^\s*(can we|could you|please|can you)\s+"#, with: "", options: .regularExpression)
        .replacingOccurrences(of: #"(?i)\b(create|set up|setup|make)\s+(a\s+|an\s+)?(new\s+)?automation\??"#, with: "Automation", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: " ?.!"))
    return automationTitle(cleaned.isEmpty ? "Codex Automation" : cleaned, limit: 80)
}

private func normalizedAutomationStatus(_ value: String) -> String {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    return normalized == "INACTIVE" || normalized == "PAUSED" ? "INACTIVE" : "ACTIVE"
}

private func automationPrompt(from text: String) -> String {
    """
    \(text.trimmingCharacters(in: .whitespacesAndNewlines))

    This automation was created from Apple Messages through the Messages Codex Bridge. Use available Codex tools, plugins, skills, and apps as needed. Do not modify the Messages bridge unless the prompt explicitly asks for bridge source changes.
    """
}

private func automationRRule(from text: String, includeSeconds: Bool) -> String {
    let normalized = text.lowercased()
    let time = timeOfDay(from: text) ?? (normalized.contains("morning") ? (7, 0) : (9, 0))
    let seconds = includeSeconds ? ";BYSECOND=0" : ""
    if normalized.contains("weekly") {
        return "FREQ=WEEKLY;BYDAY=MO;BYHOUR=\(time.0);BYMINUTE=\(time.1)\(seconds)"
    }
    if normalized.contains("monthly") {
        return "FREQ=MONTHLY;BYMONTHDAY=1;BYHOUR=\(time.0);BYMINUTE=\(time.1)\(seconds)"
    }
    return "FREQ=DAILY;BYHOUR=\(time.0);BYMINUTE=\(time.1)\(seconds)"
}

private func timeOfDay(from text: String) -> (Int, Int)? {
    let pattern = #"(?i)\b(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?)\b"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          let hourRange = Range(match.range(at: 1), in: text),
          let markerRange = Range(match.range(at: 3), in: text),
          var hour = Int(text[hourRange]) else {
        return nil
    }
    let minute: Int
    if let minuteRange = Range(match.range(at: 2), in: text), let parsed = Int(text[minuteRange]) {
        minute = min(max(parsed, 0), 59)
    } else {
        minute = 0
    }
    let marker = text[markerRange].lowercased()
    if marker.contains("p"), hour < 12 {
        hour += 12
    } else if marker.contains("a"), hour == 12 {
        hour = 0
    }
    guard (0..<24).contains(hour) else { return nil }
    return (hour, minute)
}

private func writeCodexAutomation(_ draft: CodexAutomationDraft, paths: RuntimePaths, now: Date) throws -> CreatedCodexAutomation {
    try FileManager.default.createDirectory(at: paths.codexAutomationsDir, withIntermediateDirectories: true)
    let id = uniqueAutomationId(for: draft.name, automationsDir: paths.codexAutomationsDir)
    let dir = paths.codexAutomationsDir.appendingPathComponent(id)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let timestamp = Int64((now.timeIntervalSince1970 * 1000).rounded())
    let toml = automationToml(id: id, draft: draft, timestamp: timestamp)
    let file = dir.appendingPathComponent("automation.toml")
    try toml.data(using: .utf8)?.write(to: file, options: .atomic)
    return CreatedCodexAutomation(id: id, name: draft.name, rrule: draft.rrule, path: file.path)
}

private func uniqueAutomationId(for name: String, automationsDir: URL) -> String {
    let base = slugify(name).isEmpty ? "codex-automation" : slugify(name)
    var candidate = base
    var suffix = 2
    while FileManager.default.fileExists(atPath: automationsDir.appendingPathComponent(candidate).path) {
        candidate = "\(base)-\(suffix)"
        suffix += 1
    }
    return candidate
}

private func slugify(_ value: String) -> String {
    let lower = value.lowercased()
    var result = ""
    var lastWasDash = false
    for scalar in lower.unicodeScalars {
        if CharacterSet.alphanumerics.contains(scalar) {
            result.append(String(scalar))
            lastWasDash = false
        } else if !lastWasDash {
            result.append("-")
            lastWasDash = true
        }
    }
    return String(result.trimmingCharacters(in: CharacterSet(charactersIn: "-")).prefix(64))
}

private func automationToml(id: String, draft: CodexAutomationDraft, timestamp: Int64) -> String {
    var lines = [
        "version = 1",
        "id = \(tomlString(id))",
        #"kind = "cron""#,
        "name = \(tomlString(draft.name))",
        "prompt = \(tomlString(draft.prompt))",
        "status = \(tomlString(draft.status))",
        "rrule = \(tomlString(draft.rrule))",
        "model = \(tomlString(draft.model))"
    ]
    if let reasoningEffort = draft.reasoningEffort, !reasoningEffort.isEmpty {
        lines.append("reasoning_effort = \(tomlString(reasoningEffort))")
    }
    lines += [
        "execution_environment = \(tomlString(draft.executionEnvironment))",
        "cwds = \(tomlStringArray(draft.cwds))",
        "created_at = \(timestamp)",
        "updated_at = \(timestamp)"
    ]
    return lines.joined(separator: "\n") + "\n"
}

public func parseCodexAutomationSpec(_ text: String) -> CodexAutomationSpec? {
    let trimmed = stripCodeFence(text.trimmingCharacters(in: .whitespacesAndNewlines))
    guard let data = trimmed.data(using: .utf8),
          let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let name = object["name"] as? String,
          let prompt = object["prompt"] as? String,
          let rrule = object["rrule"] as? String,
          !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !rrule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return nil
    }
    return CodexAutomationSpec(
        name: name,
        prompt: prompt,
        rrule: rrule,
        model: object["model"] as? String,
        reasoningEffort: object["reasoningEffort"] as? String ?? object["reasoning_effort"] as? String,
        executionEnvironment: object["executionEnvironment"] as? String ?? object["execution_environment"] as? String,
        cwds: object["cwds"] as? [String]
    )
}

public func codexAutomationSpecDraftPrompt(userText: String, config: BridgeConfig) -> String {
    """
    Draft a Codex automation spec from this Apple Messages request.

    Return exactly one JSON object and no markdown. Do not create files. Do not modify source code. Do not call tools. Interpret the user's natural-language request the same way Codex Desktop would before calling its automation creation tool.

    Required JSON shape:
    {"name":"short title","prompt":"clear operational automation prompt","rrule":"FREQ=...","model":"model id","reasoningEffort":"none|minimal|low|medium|high|xhigh","executionEnvironment":"local|worktree","cwds":["/absolute/path or ~"]}

    Defaults:
    - Use model "gpt-5.2" unless the user requests another model.
    - Use reasoningEffort "medium" unless the task clearly needs more or less.
    - Use executionEnvironment "local" for broad personal/news/web/plugin tasks.
    - Use cwds [\(jsonString(config.codex.cwd))] for local/workspace tasks, or ["~"] only for projectless personal chat tasks.
    - Include BYSECOND=0 in RRULE wall-clock schedules.
    - Convert vague times like "7am or so" to a concrete RRULE time.
    - Rewrite the prompt into concise operational instructions; do not paste the user's text verbatim.
    - Preserve important constraints such as location, account/login context, output style, source links, and named plugins/capabilities.

    User request:
    \(userText)
    """
}

private func tomlString(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

private func tomlStringArray(_ values: [String]) -> String {
    "[" + values.map(tomlString).joined(separator: ", ") + "]"
}

private func automationTitle(_ value: String, limit: Int) -> String {
    let text = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    guard text.count > limit else { return text.isEmpty ? "Codex Automation" : text }
    return String(text.prefix(limit - 1)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
}

private func normalizedRRule(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.uppercased().hasPrefix("RRULE:") {
        return String(trimmed.dropFirst("RRULE:".count))
    }
    return trimmed
}

private func stripCodeFence(_ value: String) -> String {
    guard value.hasPrefix("```") else { return value }
    var lines = value.components(separatedBy: .newlines)
    if !lines.isEmpty { lines.removeFirst() }
    if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) == "```" {
        lines.removeLast()
    }
    return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
}

private func jsonString(_ value: String) -> String {
    let data = try? JSONSerialization.data(withJSONObject: [value])
    let encoded = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\(value)\"]"
    return String(encoded.dropFirst().dropLast())
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
