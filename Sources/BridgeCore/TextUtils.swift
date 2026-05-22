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

public func outboundSendStatusText(_ send: OutboundSendRecord?) -> String {
    guard let send else { return "none" }
    var parts = [
        "\(send.kind) \(send.status)",
        "to \(send.recipient) via \(send.service)",
        "attempt \(send.attemptId)"
    ]
    if let artifact = send.artifact {
        parts.append("artifact \(artifact)")
    }
    if let rowId = send.evidence?.dbRowId {
        parts.append("db row \(rowId)")
    }
    if let dbError = send.evidence?.dbError {
        parts.append("db error \(dbError)")
    }
    if let transferState = send.evidence?.transferState {
        parts.append("transfer_state \(transferState)")
    }
    if let delivered = send.evidence?.dateDelivered {
        parts.append("date_delivered \(delivered)")
    }
    if send.retryable {
        parts.append("retryable")
    }
    if let error = send.error, !error.isEmpty {
        let short = error.count > 160 ? String(error.prefix(160)) : error
        parts.append("error \(short)")
    } else if let detail = send.evidence?.detail, !detail.isEmpty {
        parts.append(detail)
    }
    return parts.joined(separator: "; ")
}

public func recentMediaRefsStatusText(_ refs: [RecentMediaRef]) -> String {
    guard !refs.isEmpty else { return "none" }
    let latest = refs.sorted { lhs, rhs in
        if lhs.createdAt == rhs.createdAt { return lhs.path < rhs.path }
        return lhs.createdAt < rhs.createdAt
    }.suffix(3)
    let details = latest.map { ref in
        var parts = [
            "\(ref.direction) \(ref.kind)",
            "row \(ref.rowId.map(String.init) ?? "none")",
            ref.transferName ?? URL(fileURLWithPath: ref.path).lastPathComponent,
            ref.exists && FileManager.default.fileExists(atPath: ref.path) ? "exists" : "missing"
        ]
        parts.append(ref.path)
        return parts.joined(separator: " ")
    }.joined(separator: " | ")
    return "\(refs.count) ref(s); latest: \(details)"
}
