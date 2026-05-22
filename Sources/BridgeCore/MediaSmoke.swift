import Foundation

public struct InboundImageSmokeRequest: Equatable, Sendable {
    public var marker: String
    public var mediaRef: RecentMediaRef
    public var request: PromptRequest

    public init(marker: String, mediaRef: RecentMediaRef, request: PromptRequest) {
        self.marker = marker
        self.mediaRef = mediaRef
        self.request = request
    }
}

public func buildInboundImageSmokeRequest(
    recipient: String,
    service: String,
    recentMediaRefs: [RecentMediaRef],
    now: Date = Date(),
    marker: String = "CODEXMSGCTL_SMOKE_INBOUND_IMAGE_\(UUID().uuidString)"
) throws -> InboundImageSmokeRequest {
    guard let ref = recentMediaRefs.reversed().first(where: { mediaRef in
        mediaRef.direction == "inbound" &&
            mediaRef.kind == "image" &&
            mediaRef.handleId == recipient &&
            mediaRef.service == service &&
            mediaRef.exists &&
            appServerSupportedLocalImagePath(mediaRef.path) &&
            FileManager.default.fileExists(atPath: mediaRef.path)
    }) else {
        throw StoreError.validation("Smoke inbound-image-check failed: no usable app-server-compatible recent inbound image for \(recipient) via \(service). Send a trusted image to the bridge first, wait for status to show it under Recent media refs, then rerun this smoke.")
    }
    let nowText = DateCodec.iso(now)
    let batch = PendingBatch(
        handleId: recipient,
        service: service,
        startedAt: nowText,
        deadlineAt: nowText,
        items: [
            MessageItem(
                rowId: 0,
                guid: "codexmsgctl-smoke-\(marker)",
                text: "For that image, reply only with \(marker) SUCCESS if an image is attached, or \(marker) BLOCKED and the exact blocker text if no image is attached.",
                handleId: recipient,
                service: service,
                receivedAt: nowText,
                attachments: []
            )
        ]
    )
    let request = buildPromptRequest(from: batch, recentMediaRefs: recentMediaRefs)
    guard request.attachments.contains(where: { $0.kind == "image" && $0.absolutePath == ref.path && $0.exists }) else {
        throw StoreError.validation("Smoke inbound-image-check failed: prompt builder did not attach recent inbound image \(ref.path).")
    }
    return InboundImageSmokeRequest(marker: marker, mediaRef: ref, request: request)
}

public func latestTrustedInboundImageMediaRef(
    config: BridgeConfig,
    recipient: String,
    service: String,
    homeDir: String = NSHomeDirectory(),
    runner: ProcessRunner = ProcessRunner()
) async throws -> RecentMediaRef? {
    let values = trustedSenderComparisonValues(recipient)
    guard !values.isEmpty else { return nil }
    let phoneExpression = normalizedSQLHandleExpression("h.id")
    let textExpression = "lower(coalesce(h.id, ''))"
    let senderClause = values.map { value in
        let escaped = value.replacingOccurrences(of: "'", with: "''")
        if value.allSatisfy(\.isNumber) {
            return "\(phoneExpression) = '\(escaped)'"
        }
        return "\(textExpression) = '\(escaped.lowercased())'"
    }.joined(separator: " OR ")
    let serviceLiteral = sqliteStringLiteral(service)
    let sql = """
    SELECT
      m.ROWID AS rowid,
      m.guid AS guid,
      a.filename AS filename,
      a.transfer_name AS transferName,
      a.mime_type AS mimeType,
      a.uti AS uti,
      CAST(m.date AS TEXT) AS rawDate
    FROM message m
    LEFT JOIN handle h ON h.ROWID = m.handle_id
    JOIN message_attachment_join maj ON maj.message_id = m.ROWID
    JOIN attachment a ON a.ROWID = maj.attachment_id
    WHERE m.is_from_me = 0
      AND COALESCE(m.service, h.service, 'iMessage') = \(serviceLiteral)
      AND (\(senderClause))
    ORDER BY m.ROWID DESC, a.ROWID DESC
    LIMIT 25;
    """
    let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", "-json", config.messagesDbPath, sql])
    let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !output.isEmpty else { return nil }
    let rows = try JSONDecoder().decode([SQLiteRow].self, from: Data(output.utf8))
    for row in rows {
        let originalPath = normalizeMessagesAttachmentPath(row.string("filename"), homeDir: homeDir)
        let kind = classifyAttachment(mimeType: row.string("mimeType"), uti: row.string("uti"), absolutePath: originalPath)
        guard kind == "image", let originalPath, FileManager.default.fileExists(atPath: originalPath) else { continue }
        guard let path = try await appServerCompatibleImagePath(originalPath, runner: runner) else { continue }
        return RecentMediaRef(
            direction: "inbound",
            rowId: row.int64("rowid"),
            handleId: recipient,
            service: service,
            path: path,
            transferName: URL(fileURLWithPath: path).lastPathComponent,
            kind: kind,
            createdAt: DateCodec.iso(Date()),
            exists: true
        )
    }
    return nil
}

public func appServerSupportedLocalImagePath(_ path: String) -> Bool {
    ["jpg", "jpeg", "png", "gif"].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
}

public func appServerCompatibleImagePath(_ path: String, runner: ProcessRunner = ProcessRunner()) async throws -> String? {
    guard FileManager.default.fileExists(atPath: path) else { return nil }
    if appServerSupportedLocalImagePath(path) { return path }
    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
    guard ["heic", "heif", "tif", "tiff", "webp", "bmp"].contains(ext) else { return nil }
    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MessagesCodexBridgeInboundMedia", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let output = directory.appendingPathComponent("\(UUID().uuidString).jpg")
    _ = try await runner.run("/usr/bin/sips", ["-s", "format", "jpeg", "-s", "formatOptions", "90", "-Z", "2400", path, "--out", output.path], timeoutMs: 20_000)
    guard FileManager.default.fileExists(atPath: output.path) else { return nil }
    return output.path
}

private func normalizeMessagesAttachmentPath(_ filename: String?, homeDir: String) -> String? {
    guard let filename, !filename.isEmpty else { return nil }
    if filename == "~" { return homeDir }
    if filename.hasPrefix("~/") {
        return URL(fileURLWithPath: homeDir).appendingPathComponent(String(filename.dropFirst(2))).path
    }
    return URL(fileURLWithPath: filename).standardized.path
}
