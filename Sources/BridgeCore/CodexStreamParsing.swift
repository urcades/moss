import Foundation

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
