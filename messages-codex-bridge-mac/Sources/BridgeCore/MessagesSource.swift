import Foundation

public protocol MessageSource {
    func initializeCursor(state: inout BridgeState) async throws
    func fetchNewMessages(afterRowId: Int64) async throws -> [MessageItem]
}

public final class SQLiteMessageSource: MessageSource {
    private let dbPath: String
    private let trustedSenders: [String]
    private let homeDir: String
    private let runner: ProcessRunner

    public init(dbPath: String, allowedSender: String, homeDir: String = NSHomeDirectory(), runner: ProcessRunner = ProcessRunner()) {
        self.dbPath = dbPath
        self.trustedSenders = normalizedTrustedSenderList([allowedSender])
        self.homeDir = homeDir
        self.runner = runner
    }

    public init(dbPath: String, trustedSenders: [String], homeDir: String = NSHomeDirectory(), runner: ProcessRunner = ProcessRunner()) {
        self.dbPath = dbPath
        self.trustedSenders = normalizedTrustedSenderList(trustedSenders)
        self.homeDir = homeDir
        self.runner = runner
    }

    public func initializeCursor(state: inout BridgeState) async throws {
        if state.lastProcessedRowId > 0 || state.lastProcessedGuid != nil { return }
        if let latest = try await latestMatchingMessage() {
            state.lastProcessedRowId = latest.rowId
            state.lastProcessedGuid = latest.guid
        }
    }

    public func latestMatchingMessage() async throws -> (rowId: Int64, guid: String)? {
        let whereClause = senderWhereClause()
        let sql = """
        SELECT m.ROWID AS rowid, m.guid AS guid
        FROM message m
        LEFT JOIN handle h ON h.ROWID = m.handle_id
        WHERE m.is_from_me = 0
          AND (\(whereClause))
          AND (
            trim(replace(COALESCE(m.text, ''), char(65532), '')) != ''
            OR EXISTS (SELECT 1 FROM message_attachment_join maj WHERE maj.message_id = m.ROWID)
          )
        ORDER BY m.ROWID DESC
        LIMIT 1;
        """
        let rows: [SQLiteRow] = try await query(sql)
        guard let row = rows.first, let id = row.int64("rowid"), let guid = row.string("guid") else { return nil }
        return (id, guid)
    }

    public func fetchNewMessages(afterRowId: Int64) async throws -> [MessageItem] {
        let sql = """
        SELECT
          m.ROWID AS rowid,
          m.guid AS guid,
          m.text AS text,
          CAST(m.date AS TEXT) AS rawDate,
          h.id AS handleId,
          COALESCE(m.service, h.service, 'iMessage') AS service,
          a.ROWID AS attachmentId,
          a.filename AS filename,
          a.mime_type AS mimeType,
          a.uti AS uti,
          a.transfer_name AS transferName
        FROM message m
        LEFT JOIN handle h ON h.ROWID = m.handle_id
        LEFT JOIN message_attachment_join maj ON maj.message_id = m.ROWID
        LEFT JOIN attachment a ON a.ROWID = maj.attachment_id
        WHERE m.ROWID > \(max(0, afterRowId))
          AND m.is_from_me = 0
          AND (\(senderWhereClause()))
        ORDER BY m.ROWID ASC, a.ROWID ASC;
        """
        return aggregateRows(try await query(sql))
    }

    private func senderWhereClause() -> String {
        let values = trustedSenders.flatMap(trustedSenderComparisonValues)
        guard !values.isEmpty else { return "1 = 0" }
        let phoneExpression = normalizedSQLHandleExpression("h.id")
        let textExpression = "lower(coalesce(h.id, ''))"
        return values.map { value in
            let escaped = value.replacingOccurrences(of: "'", with: "''")
            if value.allSatisfy(\.isNumber) {
                return "\(phoneExpression) = '\(escaped)'"
            }
            return "\(textExpression) = '\(escaped.lowercased())'"
        }.joined(separator: " OR ")
    }

    private func query<T: Decodable>(_ sql: String) async throws -> [T] {
        let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", "-json", dbPath, sql])
        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else {
            return []
        }
        return try JSONDecoder().decode([T].self, from: Data(output.utf8))
    }

    private func aggregateRows(_ rows: [SQLiteRow]) -> [MessageItem] {
        var messages: [MessageItem] = []
        var indexByRowId: [Int64: Int] = [:]
        for row in rows {
            guard let rowId = row.int64("rowid"), let guid = row.string("guid") else { continue }
            let messageIndex: Int
            if let existing = indexByRowId[rowId] {
                messageIndex = existing
            } else {
                let message = MessageItem(
                    rowId: rowId,
                    guid: guid,
                    text: cleanIncomingText(row.string("text")),
                    handleId: row.string("handleId") ?? "",
                    service: row.string("service") ?? "iMessage",
                    receivedAt: appleTimestampToISO(row.string("rawDate")),
                    attachments: []
                )
                messages.append(message)
                indexByRowId[rowId] = messages.count - 1
                messageIndex = messages.count - 1
            }
            if let attachment = attachment(from: row), !messages[messageIndex].attachments.contains(where: { $0.attachmentId == attachment.attachmentId }) {
                messages[messageIndex].attachments.append(attachment)
            }
        }
        return messages.filter { !$0.text.isEmpty || !$0.attachments.isEmpty }
    }

    private func attachment(from row: SQLiteRow) -> AttachmentRef? {
        guard let id = row.int64("attachmentId") else { return nil }
        let absolutePath = normalizeAttachmentPath(row.string("filename"))
        let exists = absolutePath.map { FileManager.default.fileExists(atPath: $0) } ?? false
        let name = row.string("transferName") ?? absolutePath.map { URL(fileURLWithPath: $0).lastPathComponent }
        return AttachmentRef(
            attachmentId: id,
            transferName: name,
            mimeType: row.string("mimeType"),
            uti: row.string("uti"),
            absolutePath: absolutePath,
            kind: classifyAttachment(mimeType: row.string("mimeType"), uti: row.string("uti"), absolutePath: absolutePath),
            exists: exists
        )
    }

    private func normalizeAttachmentPath(_ filename: String?) -> String? {
        guard let filename, !filename.isEmpty else { return nil }
        if filename == "~" { return homeDir }
        if filename.hasPrefix("~/") { return URL(fileURLWithPath: homeDir).appendingPathComponent(String(filename.dropFirst(2))).path }
        return URL(fileURLWithPath: filename).standardized.path
    }
}

public struct SQLiteRow: Decodable {
    public var values: [String: SQLiteValue]

    public init(from decoder: Decoder) throws {
        values = try [String: SQLiteValue](from: decoder)
    }

    public func string(_ key: String) -> String? {
        guard let value = values[key] else { return nil }
        switch value {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .null: return nil
        }
    }

    public func int64(_ key: String) -> Int64? {
        guard let value = values[key] else { return nil }
        switch value {
        case .int(let value): return value
        case .string(let value): return Int64(value)
        case .double(let value): return Int64(value)
        case .null: return nil
        }
    }
}

public enum SQLiteValue: Decodable {
    case string(String)
    case int(Int64)
    case double(Double)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Int64.self) { self = .int(value) }
        else if let value = try? container.decode(Double.self) { self = .double(value) }
        else { self = .string(try container.decode(String.self)) }
    }
}

public func appleTimestampToISO(_ rawValue: String?) -> String? {
    guard let rawValue, let ns = Int64(rawValue), ns != 0 else { return nil }
    let appleEpoch = Date(timeIntervalSince1970: 978_307_200)
    return DateCodec.iso(appleEpoch.addingTimeInterval(Double(ns) / 1_000_000_000))
}

public func classifyAttachment(mimeType: String?, uti: String?, absolutePath: String?) -> String {
    let mime = (mimeType ?? "").lowercased()
    let uti = (uti ?? "").lowercased()
    let ext = absolutePath.map { URL(fileURLWithPath: $0).pathExtension.lowercased() } ?? ""
    if mime.hasPrefix("image/") || uti.hasPrefix("public.image") || ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"].contains(ext) {
        return "image"
    }
    if mime == "application/pdf" || uti == "com.adobe.pdf" || ext == "pdf" {
        return "pdf"
    }
    return "unsupported"
}
