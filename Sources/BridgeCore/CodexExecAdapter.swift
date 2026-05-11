import Foundation

public final class CodexExecAdapter: CodexBackend {
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
                throw CodexBackendFailure(message: "Codex completed without a final reply.", stdout: result.stdout, stderr: result.stderr, timedOut: false, blockedText: permissionBlock(in: result.stdout + "\n" + result.stderr))
            }
            return CodexResponse(text: finalText, sessionId: extractSessionId(events: events) ?? sessionId, stdout: result.stdout, stderr: result.stderr, args: args, outputPath: outputPath)
        } catch let error as ProcessRunnerError {
            switch error {
            case .blocked(let message, let result):
                let blocked = permissionBlock(in: [message, result.stdout, result.stderr].joined(separator: "\n")) ?? safeUserVisibleBlockerText(message)
                throw CodexBackendFailure(
                    message: blocked ?? "Codex was blocked by a local automation request.",
                    stdout: result.stdout,
                    stderr: result.stderr,
                    timedOut: false,
                    blockedText: blocked
                )
            default:
                let text = String(describing: error)
                throw CodexBackendFailure(message: text, stdout: "", stderr: text, timedOut: text.contains("timed out"), blockedText: permissionBlock(in: text))
            }
        }
    }
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

private func imagePaths(from attachments: [AttachmentRef]) -> [String] {
    attachments.compactMap { $0.kind == "image" && $0.exists ? $0.absolutePath : nil }
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
