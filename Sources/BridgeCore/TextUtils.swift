import Foundation

public func cleanIncomingText(_ text: String?) -> String {
    (text ?? "").replacingOccurrences(of: "\u{fffc}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
}

public func stripANSI(_ text: String) -> String {
    text.replacingOccurrences(of: #"\u001B\[[0-9;]*[A-Za-z]"#, with: "", options: .regularExpression)
}

public func cleanPlainText(_ text: String) -> String {
    stripANSI(text).trimmingCharacters(in: .whitespacesAndNewlines)
}

public func stripBridgeOnlyBlocks(_ text: String) -> String {
    text.replacingOccurrences(
        of: #"<oai-mem-citation>[\s\S]*?</oai-mem-citation>"#,
        with: "",
        options: .regularExpression
    )
}

public let internalBridgeLeakReplacement = "I hit an internal bridge parsing error and stopped that reply before sending more details. Please try again."

public func containsInternalBridgeLeak(_ text: String) -> Bool {
    let lower = stripANSI(text).lowercased()
    let markers = [
        "\"base_instructions\"",
        "\"type\":\"session_meta\"",
        "\"type\":\"response_item\"",
        "\"type\":\"item.completed\"",
        "memory_summary begins",
        "<permissions instructions>",
        "<skills_instructions>",
        "<plugins_instructions>",
        "<oai-mem-citation>",
        "you are codex, a coding agent",
        "filesystem sandboxing defines",
        "available plugins",
        "available skills",
        "knowledge cutoff:"
    ]
    return markers.contains { lower.contains($0) }
}

public func safeUserVisibleText(_ text: String) -> String {
    let stripped = stripBridgeOnlyBlocks(text).trimmingCharacters(in: .whitespacesAndNewlines)
    return containsInternalBridgeLeak(stripped) ? internalBridgeLeakReplacement : stripped
}

public func safeUserVisibleBlockerText(_ text: String) -> String? {
    let clean = cleanPlainText(stripBridgeOnlyBlocks(text))
    guard !clean.isEmpty, !containsInternalBridgeLeak(clean) else { return nil }
    if clean.count > 600 {
        return String(clean.prefix(600)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return clean
}

public func chunkMessageText(_ text: String, chunkSize: Int) -> [String] {
    let clean = cleanPlainText(safeUserVisibleText(text))
    guard clean.count > chunkSize, chunkSize > 0 else { return clean.isEmpty ? [] : [clean] }
    var chunks: [String] = []
    var remaining = clean[...]
    while !remaining.isEmpty {
        let end = remaining.index(remaining.startIndex, offsetBy: min(chunkSize, remaining.count))
        var sliceEnd = end
        if end < remaining.endIndex, let newline = remaining[..<end].lastIndex(of: "\n") {
            sliceEnd = newline
        } else if end < remaining.endIndex, let space = remaining[..<end].lastIndex(of: " ") {
            sliceEnd = space
        }
        let chunk = remaining[..<sliceEnd].trimmingCharacters(in: .whitespacesAndNewlines)
        if !chunk.isEmpty { chunks.append(String(chunk)) }
        remaining = remaining[sliceEnd...].drop { $0 == " " || $0 == "\n" }
    }
    return chunks
}
