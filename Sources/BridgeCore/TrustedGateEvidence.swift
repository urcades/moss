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
    public var followUpInboundRowId: Int64?
    public var followUpInboundGuid: String?
    public var followUpInboundAt: String?
    public var completionOutboundRowId: Int64?
    public var completionOutboundGuid: String?
    public var completionOutboundError: Int?
    public var completionOutboundDateDelivered: Int64?
    public var completionOutboundSnippet: String?

    public init(
        command: String,
        inboundRowId: Int64? = nil,
        inboundGuid: String? = nil,
        inboundAt: String? = nil,
        outboundRowId: Int64? = nil,
        outboundGuid: String? = nil,
        outboundError: Int? = nil,
        outboundDateDelivered: Int64? = nil,
        outboundSnippet: String? = nil,
        followUpInboundRowId: Int64? = nil,
        followUpInboundGuid: String? = nil,
        followUpInboundAt: String? = nil,
        completionOutboundRowId: Int64? = nil,
        completionOutboundGuid: String? = nil,
        completionOutboundError: Int? = nil,
        completionOutboundDateDelivered: Int64? = nil,
        completionOutboundSnippet: String? = nil
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
        self.followUpInboundRowId = followUpInboundRowId
        self.followUpInboundGuid = followUpInboundGuid
        self.followUpInboundAt = followUpInboundAt
        self.completionOutboundRowId = completionOutboundRowId
        self.completionOutboundGuid = completionOutboundGuid
        self.completionOutboundError = completionOutboundError
        self.completionOutboundDateDelivered = completionOutboundDateDelivered
        self.completionOutboundSnippet = completionOutboundSnippet
    }

    public var status: String {
        guard inboundRowId != nil else { return "missing-inbound" }
        guard outboundRowId != nil else { return "missing-outbound" }
        if let outboundError, outboundError != 0 { return "outbound-error-\(outboundError)" }
        if commandRequiresTrustedFollowUp(command) {
            guard followUpInboundRowId != nil else { return "awaiting-followup" }
            guard completionOutboundRowId != nil else { return "awaiting-completion" }
            if let completionOutboundError, completionOutboundError != 0 {
                return "completion-outbound-error-\(completionOutboundError)"
            }
        }
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
    "/codex smoke edit-image-check",
    "/codex smoke app-server",
    "/codex smoke inbound-image-check",
    "/codex smoke outbound-image-check",
    "/codex smoke chrome",
    "/codex smoke browser",
    "/codex smoke computer-use",
    "/codex smoke automation",
    "/codex smoke callback",
    "/codex smoke app-server-callback",
    "/codex smoke mcp-elicitation-callback"
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
    let outboundSenderClause = trustedSenderSQLClause(column: "oh.id", values: values)
    let followUpSenderClause = trustedSenderSQLClause(column: "fh.id", values: values)
    let completionOutboundSenderClause = trustedSenderSQLClause(column: "coh.id", values: values)
    let nextInboundCommandSenderClause = trustedSenderSQLClause(column: "bh.id", values: values)
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
      substr(COALESCE(NULLIF(o.text, ''), CAST(o.attributedBody AS TEXT), ''), 1, 160) AS outboundSnippet,
      f.ROWID AS followUpInboundRowId,
      f.guid AS followUpInboundGuid,
      CAST(f.date AS TEXT) AS followUpInboundRawDate,
      c.ROWID AS completionOutboundRowId,
      c.guid AS completionOutboundGuid,
      COALESCE(c.error, 0) AS completionOutboundError,
      COALESCE(c.date_delivered, 0) AS completionOutboundDateDelivered,
      substr(COALESCE(NULLIF(c.text, ''), CAST(c.attributedBody AS TEXT), ''), 1, 160) AS completionOutboundSnippet
    FROM latest_inbound li
    LEFT JOIN message o ON o.ROWID = (
      SELECT MIN(m2.ROWID)
      FROM message m2
      LEFT JOIN handle oh ON oh.ROWID = m2.handle_id
      WHERE m2.is_from_me = 1
        AND m2.ROWID > li.inboundRowId
        AND COALESCE(m2.service, oh.service, \(serviceLiteral)) = \(serviceLiteral)
        AND (m2.handle_id IS NULL OR \(outboundSenderClause))
    )
    LEFT JOIN message f ON f.ROWID = (
      SELECT MIN(m3.ROWID)
      FROM message m3
      LEFT JOIN handle fh ON fh.ROWID = m3.handle_id
      WHERE li.command IN ('/codex smoke callback', '/codex smoke app-server-callback', '/codex smoke mcp-elicitation-callback')
        AND m3.is_from_me = 0
        AND m3.ROWID > o.ROWID
        AND COALESCE(m3.service, fh.service, \(serviceLiteral)) = \(serviceLiteral)
        AND (\(followUpSenderClause))
        AND trim(COALESCE(m3.text, '')) != ''
        AND lower(trim(COALESCE(m3.text, ''))) NOT LIKE '/codex%'
        AND m3.ROWID < COALESCE((
          SELECT MIN(bound.ROWID)
          FROM message bound
          LEFT JOIN handle bh ON bh.ROWID = bound.handle_id
          WHERE bound.is_from_me = 0
            AND bound.ROWID > li.inboundRowId
            AND COALESCE(bound.service, bh.service, \(serviceLiteral)) = \(serviceLiteral)
            AND (\(nextInboundCommandSenderClause))
            AND lower(trim(COALESCE(bound.text, ''))) IN (\(commandList))
        ), 9223372036854775807)
    )
    LEFT JOIN message c ON c.ROWID = (
      SELECT MIN(m4.ROWID)
      FROM message m4
      LEFT JOIN handle coh ON coh.ROWID = m4.handle_id
      WHERE li.command IN ('/codex smoke callback', '/codex smoke app-server-callback', '/codex smoke mcp-elicitation-callback')
        AND f.ROWID IS NOT NULL
        AND m4.is_from_me = 1
        AND m4.ROWID > f.ROWID
        AND COALESCE(m4.service, coh.service, \(serviceLiteral)) = \(serviceLiteral)
        AND (m4.handle_id IS NULL OR \(completionOutboundSenderClause))
        AND (
          (li.command = '/codex smoke callback'
            AND lower(COALESCE(NULLIF(m4.text, ''), CAST(m4.attributedBody AS TEXT), '')) LIKE '%smoke callback passed:%')
          OR
          (li.command = '/codex smoke app-server-callback'
            AND (
              lower(COALESCE(NULLIF(m4.text, ''), CAST(m4.attributedBody AS TEXT), '')) LIKE '%success callback reply:%'
              OR lower(COALESCE(NULLIF(m4.text, ''), CAST(m4.attributedBody AS TEXT), '')) LIKE '%callback completed with%'
            ))
          OR
          (li.command = '/codex smoke mcp-elicitation-callback'
            AND lower(COALESCE(NULLIF(m4.text, ''), CAST(m4.attributedBody AS TEXT), '')) LIKE '%success elicitation reply:%')
        )
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
                outboundSnippet: row.string("outboundSnippet"),
                followUpInboundRowId: row.int64("followUpInboundRowId"),
                followUpInboundGuid: row.string("followUpInboundGuid"),
                followUpInboundAt: appleTimestampToISO(row.string("followUpInboundRawDate")),
                completionOutboundRowId: row.int64("completionOutboundRowId"),
                completionOutboundGuid: row.string("completionOutboundGuid"),
                completionOutboundError: row.int64("completionOutboundError").map(Int.init),
                completionOutboundDateDelivered: row.int64("completionOutboundDateDelivered"),
                completionOutboundSnippet: row.string("completionOutboundSnippet")
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
        if let followUpInboundRowId = item.followUpInboundRowId {
            parts.append("follow-up inbound row \(followUpInboundRowId)")
        }
        if let completionOutboundRowId = item.completionOutboundRowId {
            parts.append("completion outbound row \(completionOutboundRowId)")
        }
        if let completionOutboundError = item.completionOutboundError,
           item.completionOutboundRowId != nil,
           completionOutboundError != 0 {
            parts.append("completion error \(completionOutboundError)")
        }
        if let completionSnippet = item.completionOutboundSnippet, !completionSnippet.isEmpty {
            parts.append("completion \"\(completionSnippet)\"")
        }
        if item.status == "awaiting-followup" {
            parts.append("Reply in Apple Messages to complete \(item.command)")
        } else if item.status == "awaiting-completion" {
            parts.append("Waiting for completion reply for \(item.command)")
        }
        lines.append(parts.joined(separator: "; "))
    }
    let missingInbound = evidence.filter { $0.status == "missing-inbound" }
    if let next = missingInbound.first {
        lines.append("")
        lines.append("Missing trusted inbound commands: \(missingInbound.count)")
        lines.append("Next trusted command to send from Apple Messages: \(next.command)")
    }
    return lines.joined(separator: "\n")
}

private func commandRequiresTrustedFollowUp(_ command: String) -> Bool {
    let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized == "/codex smoke callback" || normalized == "/codex smoke app-server-callback" || normalized == "/codex smoke mcp-elicitation-callback"
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
