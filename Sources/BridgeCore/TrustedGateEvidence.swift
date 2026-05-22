import Foundation

public struct TrustedGateEvidence: Codable, Equatable, Sendable {
    public var command: String
    public var inboundRowId: Int64?
    public var inboundGuid: String?
    public var inboundAt: String?
    public var outboundRowId: Int64?
    public var outboundGuid: String?
    public var outboundError: Int?
    public var outboundDateDelivered: Int64?
    public var outboundSnippet: String?

    public init(
        command: String,
        inboundRowId: Int64? = nil,
        inboundGuid: String? = nil,
        inboundAt: String? = nil,
        outboundRowId: Int64? = nil,
        outboundGuid: String? = nil,
        outboundError: Int? = nil,
        outboundDateDelivered: Int64? = nil,
        outboundSnippet: String? = nil
    ) {
        self.command = command
        self.inboundRowId = inboundRowId
        self.inboundGuid = inboundGuid
        self.inboundAt = inboundAt
        self.outboundRowId = outboundRowId
        self.outboundGuid = outboundGuid
        self.outboundError = outboundError
        self.outboundDateDelivered = outboundDateDelivered
        self.outboundSnippet = outboundSnippet
    }

    public var status: String {
        guard inboundRowId != nil else { return "missing-inbound" }
        guard outboundRowId != nil else { return "missing-outbound" }
        if let outboundError, outboundError != 0 { return "outbound-error-\(outboundError)" }
        return "observed"
    }
}

public let defaultTrustedGateCommands: [String] = [
    "/codex status",
    "/codex gates",
    "/codex smoke text",
    "/codex smoke attachment",
    "/codex smoke bridge-attach",
    "/codex smoke generated-image",
    "/codex smoke app-server",
    "/codex smoke inbound-image-check",
    "/codex smoke outbound-image-check",
    "/codex smoke chrome",
    "/codex smoke browser",
    "/codex smoke computer-use",
    "/codex smoke automation",
    "/codex smoke callback",
    "/codex smoke app-server-callback"
]

public func trustedGateEvidence(
    config: BridgeConfig,
    recipient: String? = nil,
    service: String = "iMessage",
    commands: [String] = defaultTrustedGateCommands,
    runner: ProcessRunner = ProcessRunner()
) async throws -> [TrustedGateEvidence] {
    let trusted = recipient ?? config.allowedSender
    let values = trustedSenderComparisonValues(trusted)
    guard !values.isEmpty else {
        return commands.map { TrustedGateEvidence(command: $0) }
    }
    let senderClause = trustedSenderSQLClause(column: "h.id", values: values)
    let commandList = commands.map { sqliteStringLiteral($0.lowercased()) }.joined(separator: ", ")
    let serviceLiteral = sqliteStringLiteral(service)
    let sql = """
    WITH trusted_inbound AS (
      SELECT
        lower(trim(COALESCE(m.text, ''))) AS command,
        m.ROWID AS inboundRowId,
        m.guid AS inboundGuid,
        CAST(m.date AS TEXT) AS inboundRawDate
      FROM message m
      LEFT JOIN handle h ON h.ROWID = m.handle_id
      WHERE m.is_from_me = 0
        AND COALESCE(m.service, h.service, 'iMessage') = \(serviceLiteral)
        AND (\(senderClause))
        AND lower(trim(COALESCE(m.text, ''))) IN (\(commandList))
    ),
    latest_inbound AS (
      SELECT ti.*
      FROM trusted_inbound ti
      JOIN (
        SELECT command, MAX(inboundRowId) AS maxInboundRowId
        FROM trusted_inbound
        GROUP BY command
      ) latest ON latest.command = ti.command AND latest.maxInboundRowId = ti.inboundRowId
    )
    SELECT
      li.command AS command,
      li.inboundRowId AS inboundRowId,
      li.inboundGuid AS inboundGuid,
      li.inboundRawDate AS inboundRawDate,
      o.ROWID AS outboundRowId,
      o.guid AS outboundGuid,
      COALESCE(o.error, 0) AS outboundError,
      COALESCE(o.date_delivered, 0) AS outboundDateDelivered,
      substr(COALESCE(o.text, ''), 1, 160) AS outboundSnippet
    FROM latest_inbound li
    LEFT JOIN message o ON o.ROWID = (
      SELECT MIN(m2.ROWID)
      FROM message m2
      WHERE m2.is_from_me = 1
        AND m2.ROWID > li.inboundRowId
    )
    ORDER BY li.inboundRowId DESC;
    """
    let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", "-json", config.messagesDbPath, sql])
    let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let rows = output.isEmpty ? [] : try JSONDecoder().decode([SQLiteRow].self, from: Data(output.utf8))
    var byCommand = Dictionary(uniqueKeysWithValues: rows.compactMap { row -> (String, TrustedGateEvidence)? in
        guard let command = row.string("command") else { return nil }
        return (
            command,
            TrustedGateEvidence(
                command: command,
                inboundRowId: row.int64("inboundRowId"),
                inboundGuid: row.string("inboundGuid"),
                inboundAt: appleTimestampToISO(row.string("inboundRawDate")),
                outboundRowId: row.int64("outboundRowId"),
                outboundGuid: row.string("outboundGuid"),
                outboundError: row.int64("outboundError").map(Int.init),
                outboundDateDelivered: row.int64("outboundDateDelivered"),
                outboundSnippet: row.string("outboundSnippet")
            )
        )
    })
    return commands.map { command in
        byCommand.removeValue(forKey: command.lowercased()) ?? TrustedGateEvidence(command: command)
    }
}

public func formatTrustedGateEvidence(_ evidence: [TrustedGateEvidence]) -> String {
    guard !evidence.isEmpty else { return "Trusted Messages gate evidence: no commands configured." }
    var lines = ["Trusted Messages gate evidence:"]
    for item in evidence {
        var parts = ["- \(item.command): \(item.status)"]
        if let inboundRowId = item.inboundRowId {
            parts.append("inbound row \(inboundRowId)")
        }
        if let outboundRowId = item.outboundRowId {
            parts.append("outbound row \(outboundRowId)")
        }
        if let outboundError = item.outboundError {
            parts.append("error \(outboundError)")
        }
        if let snippet = item.outboundSnippet, !snippet.isEmpty {
            parts.append("reply \"\(snippet)\"")
        }
        lines.append(parts.joined(separator: "; "))
    }
    return lines.joined(separator: "\n")
}

private func trustedSenderSQLClause(column: String, values: [String]) -> String {
    let phoneExpression = normalizedSQLHandleExpression(column)
    let textExpression = "lower(coalesce(\(column), ''))"
    return values.map { value in
        let literal = sqliteStringLiteral(value.lowercased())
        if value.allSatisfy(\.isNumber) {
            return "\(phoneExpression) = \(literal)"
        }
        return "\(textExpression) = \(literal)"
    }.joined(separator: " OR ")
}
