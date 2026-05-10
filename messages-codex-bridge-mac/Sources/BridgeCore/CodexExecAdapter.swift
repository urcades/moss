import Foundation

public struct CodexExecFailure: Error, CustomStringConvertible {
    public var message: String
    public var stdout: String
    public var stderr: String
    public var timedOut: Bool
    public var blockedText: String?

    public var description: String { message }
}

public final class CodexExecAdapter {
    private let config: BridgeConfig
    private let paths: RuntimePaths
    private let runner: ProcessRunner

    public init(config: BridgeConfig, paths: RuntimePaths, runner: ProcessRunner = ProcessRunner()) {
        self.config = config
        self.paths = paths
        self.runner = runner
    }

    public func invoke(_ request: PromptRequest, sessionId: String? = nil) async throws -> CodexResponse {
        try await invoke(request, sessionId: sessionId, onEvent: nil)
    }

    public func invoke(_ request: PromptRequest, sessionId: String? = nil, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse {
        let outputPath = try createOutputPath(paths: paths)
        let args = buildCodexExecArgs(config: config, outputPath: outputPath, sessionId: sessionId, imagePaths: imagePaths(from: request.attachments))
        let prompt = composeCodexPrompt(request.promptText, stylePrompt: config.codex.stylePrompt)
        let parser = CodexStreamParser()

        do {
            let result = try await runner.run(
                config.codex.command,
                args,
                cwd: config.codex.cwd,
                stdin: prompt,
                timeoutMs: config.timeoutMs,
                outputInspector: codexAutomationBlock(in:),
                outputHandler: { stream, chunk in
                    for event in parser.consume(chunk, stream: stream) {
                        onEvent?(event)
                    }
                },
                onStart: { pid in
                    onEvent?(.processStarted(pid))
                }
            )
            let events = parseJSONLines(result.stdout + "\n" + result.stderr)
            let outputText = (try? String(contentsOfFile: outputPath, encoding: .utf8)).map(cleanPlainText) ?? ""
            let finalText = outputText.isEmpty ? extractFinalText(events: events, stdout: result.stdout) : outputText
            guard !finalText.isEmpty else {
                throw CodexExecFailure(message: "Codex completed without a final reply.", stdout: result.stdout, stderr: result.stderr, timedOut: false, blockedText: permissionBlock(in: result.stdout + "\n" + result.stderr))
            }
            return CodexResponse(text: finalText, sessionId: extractSessionId(events: events) ?? sessionId, stdout: result.stdout, stderr: result.stderr, args: args, outputPath: outputPath)
        } catch let error as ProcessRunnerError {
            switch error {
            case .blocked(let message, let result):
                let blocked = permissionBlock(in: [message, result.stdout, result.stderr].joined(separator: "\n")) ?? safeUserVisibleBlockerText(message)
                throw CodexExecFailure(
                    message: blocked ?? "Codex was blocked by a local automation request.",
                    stdout: result.stdout,
                    stderr: result.stderr,
                    timedOut: false,
                    blockedText: blocked
                )
            default:
                let text = String(describing: error)
                throw CodexExecFailure(message: text, stdout: "", stderr: text, timedOut: text.contains("timed out"), blockedText: permissionBlock(in: text))
            }
        }
    }
}

public enum CodexStreamEvent: Equatable, Sendable {
    case processStarted(Int32)
    case sessionStarted(String)
    case progress(String)
    case milestone(String)
    case blocker(String)
    case question(String)
}

public final class CodexStreamParser: @unchecked Sendable {
    private let lock = NSLock()
    private var stdoutRemainder = ""
    private var stderrRemainder = ""

    public init() {}

    public func consume(_ chunk: String, stream: ProcessOutputStream) -> [CodexStreamEvent] {
        lock.lock()
        defer { lock.unlock() }
        var buffer = (stream == .stdout ? stdoutRemainder : stderrRemainder) + chunk
        let endsWithNewline = buffer.hasSuffix("\n")
        var lines = buffer.components(separatedBy: .newlines)
        let remainder = endsWithNewline ? "" : (lines.popLast() ?? "")
        buffer = ""
        if stream == .stdout {
            stdoutRemainder = remainder
        } else {
            stderrRemainder = remainder
        }
        return lines.flatMap(parseCodexEventLine)
    }

    private func parseCodexEventLine(_ line: String) -> [CodexStreamEvent] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard trimmed.first == "{", trimmed.last == "}", let data = trimmed.data(using: .utf8),
              let event = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            if trimmed.first == "{", trimmed.last == "}" {
                return []
            }
            if let block = permissionBlock(in: trimmed) {
                return [.blocker(block)]
            }
            return []
        }
        var appServerProgress = codexProgressSummary(from: event).map { [CodexStreamEvent.progress($0)] } ?? []
        if event["type"] as? String == "session_meta",
           let payload = event["payload"] as? [String: Any],
           let id = payload["id"] as? String {
            appServerProgress.append(.sessionStarted(id))
            return appServerProgress
        }
        if event["type"] as? String == "thread.started",
           let id = event["thread_id"] as? String {
            appServerProgress.append(.sessionStarted(id))
            return appServerProgress
        }
        if event["type"] as? String == "item.completed",
           let item = event["item"] as? [String: Any],
           let toolText = toolResultText(from: item),
           let block = permissionBlock(in: toolText) {
            appServerProgress.append(.blocker(block))
            return appServerProgress
        }
        guard let payload = event["payload"] as? [String: Any] else { return appServerProgress }
        let type = payload["type"] as? String ?? ""
        let text = searchableText(payload["message"] ?? payload["text"] ?? payload["output"] ?? payload["content"] ?? "")
        var results = markerEvents(in: text)
        if type == "function_call_output" || type == "message" || type == "agent_message" {
            if let block = permissionBlock(in: text) {
                results.append(.blocker(block))
            }
        }
        if results.isEmpty, event["type"] as? String == "event_msg", type == "agent_message", let message = payload["message"] as? String, !message.isEmpty {
            results.append(.progress(cleanPlainText(message)))
        }
        if !appServerProgress.isEmpty {
            results = appServerProgress + results
        }
        return results
    }
}

public func composeCodexPrompt(_ promptText: String, stylePrompt: String?) -> String {
    [BridgeConstants.baseBridgeInstructions, stylePrompt, promptText]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
}

public func buildCodexExecArgs(config: BridgeConfig, outputPath: String, sessionId: String?, imagePaths: [String]) -> [String] {
    var args = sessionId == nil ? ["exec"] : ["exec", "resume"]
    args += ["--json", "--output-last-message", outputPath, "--skip-git-repo-check", "--dangerously-bypass-approvals-and-sandbox"]
    if sessionId == nil {
        args += ["--cd", config.codex.cwd]
    }
    if let model = config.codex.model, !model.isEmpty {
        args += ["-m", model]
    }
    if sessionId == nil, let effort = config.codex.reasoningEffort, !effort.isEmpty {
        args += ["-c", "model_reasoning_effort=\"\(effort)\""]
    }
    args += config.codex.extraArgs
    for imagePath in imagePaths {
        args += ["-i", imagePath]
    }
    if let sessionId {
        args.append(sessionId)
    }
    args.append("-")
    return args
}

public func permissionBlock(in text: String) -> String? {
    let patterns = [
        "Apple event error -1743",
        "Apple event error -10000",
        "cgWindowNotFound",
        "Sender process is not authenticated",
        "Computer Use permission request canceled",
        "You must enable 'Allow remote automation'",
        "Allow remote automation",
        "could not create image from window",
        "CGDisplayCreateImage is unavailable",
        "CGWindowListCreateImage is unavailable",
        "not authorized to send Apple events",
        "operation not permitted"
    ]
    return stripANSI(text)
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .compactMap { line -> String? in
            guard !line.isEmpty, !containsInternalBridgeLeak(line) else { return nil }
            guard patterns.contains(where: { line.localizedCaseInsensitiveContains($0) }) else { return nil }
            return safeUserVisibleBlockerText(line)
        }
        .first
}

public func codexAutomationBlock(in text: String) -> String? {
    let cleanText = stripANSI(text)
    for line in cleanText.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }
        if trimmed.first == "{", trimmed.last == "}" {
            if let data = trimmed.data(using: .utf8),
               let event = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                if event["type"] as? String == "response_item",
                   let payload = event["payload"] as? [String: Any],
                   payload["type"] as? String == "function_call_output",
                   let block = permissionBlock(in: searchableText(payload["output"] ?? "")) {
                    return block
                }
                if event["type"] as? String == "item.completed",
                   let item = event["item"] as? [String: Any],
                   let toolText = toolResultText(from: item),
                   let block = permissionBlock(in: toolText) {
                    return block
                }
            }
            continue
        } else if let block = permissionBlock(in: trimmed) {
            return block
        }
    }
    return nil
}

private func toolResultText(from item: [String: Any]) -> String? {
    let itemType = item["type"] as? String
    guard itemType == "mcp_tool_call" || itemType == "function_call" || itemType == "function_call_output" else {
        return nil
    }
    return searchableText(item["result"] ?? item["output"] ?? item["content"] ?? "")
}

public func markerEvents(in text: String) -> [CodexStreamEvent] {
    text.components(separatedBy: .newlines).compactMap { line in
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let markers: [(String, (String) -> CodexStreamEvent)] = [
            ("BRIDGE_PROGRESS:", { .progress($0) }),
            ("BRIDGE_ASK_USER:", { .question($0) }),
            ("BRIDGE_BLOCKED:", { .blocker($0) })
        ]
        for (prefix, makeEvent) in markers where trimmed.range(of: prefix, options: [.caseInsensitive, .anchored]) != nil {
            let text = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : makeEvent(text)
        }
        return nil
    }
}

private func imagePaths(from attachments: [AttachmentRef]) -> [String] {
    attachments.compactMap { $0.kind == "image" && $0.exists ? $0.absolutePath : nil }
}

public func searchableText(_ value: Any) -> String {
    if let string = value as? String { return string }
    if let array = value as? [Any] { return array.map(searchableText).joined(separator: "\n") }
    if let dict = value as? [String: Any] { return dict.values.map(searchableText).joined(separator: "\n") }
    return "\(value)"
}

private func createOutputPath(paths: RuntimePaths) throws -> String {
    try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
    let dir = paths.tmpDir.appendingPathComponent("codex-exec-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("last-message.txt").path
}

private func parseJSONLines(_ text: String) -> [[String: Any]] {
    text.components(separatedBy: .newlines).compactMap { line in
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{", trimmed.last == "}", let data = trimmed.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

private func extractSessionId(events: [[String: Any]]) -> String? {
    for event in events {
        if event["type"] as? String == "session_meta", let payload = event["payload"] as? [String: Any], let id = payload["id"] as? String {
            return id
        }
        if event["type"] as? String == "thread.started", let id = event["thread_id"] as? String {
            return id
        }
        if let id = event["session_id"] as? String ?? event["sessionId"] as? String {
            return id
        }
    }
    return nil
}

private func extractFinalText(events: [[String: Any]], stdout: String) -> String {
    let candidates = events.compactMap { event -> String? in
        let type = ((event["type"] ?? event["event"]) as? String ?? "").lowercased()
        guard type.contains("final") || type.contains("answer") || type.contains("assistant") || type.contains("message") || type.contains("response") else { return nil }
        if let text = event["text"] as? String { return text }
        if let message = event["message"] as? String { return message }
        return nil
    }
    return cleanPlainText(candidates.last ?? stdout)
}
