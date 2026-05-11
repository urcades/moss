import Foundation

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

func toolResultText(from item: [String: Any]) -> String? {
    let itemType = item["type"] as? String
    guard itemType == "mcp_tool_call" || itemType == "function_call" || itemType == "function_call_output" else {
        return nil
    }
    return searchableText(item["result"] ?? item["output"] ?? item["content"] ?? "")
}

public func searchableText(_ value: Any) -> String {
    if let string = value as? String { return string }
    if let array = value as? [Any] { return array.map(searchableText).joined(separator: "\n") }
    if let dict = value as? [String: Any] { return dict.values.map(searchableText).joined(separator: "\n") }
    return "\(value)"
}
