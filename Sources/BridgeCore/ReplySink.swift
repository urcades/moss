import Foundation

public protocol ReplySink: Sendable {
    func sendReply(recipient: String, service: String, text: String) async throws
    func sendAttachment(recipient: String, service: String, filePath: String) async throws
}

public final class AppleMessagesReplySink: ReplySink {
    private let osascriptCommand: String
    private let chunkSize: Int
    private let messagesDbPath: String?
    private let runner: ProcessRunner

    public init(osascriptCommand: String = "/usr/bin/osascript", chunkSize: Int = BridgeConstants.defaultChunkSize, messagesDbPath: String? = nil, runner: ProcessRunner = ProcessRunner()) {
        self.osascriptCommand = osascriptCommand
        self.chunkSize = chunkSize
        self.messagesDbPath = messagesDbPath
        self.runner = runner
    }

    public func sendReply(recipient: String, service: String, text: String) async throws {
        for chunk in chunkMessageText(text, chunkSize: chunkSize) {
            try await sendChunk(recipient: recipient, service: service, text: chunk)
        }
    }

    public func sendAttachment(recipient: String, service: String, filePath: String) async throws {
        let serviceType = service.lowercased().contains("sms") ? "SMS" : "iMessage"

        if isClipboardSendableImage(filePath) {
            let clipboardPath = try await clipboardPreferredImagePath(from: filePath)
            try await sendClipboardImage(recipient: recipient, serviceType: serviceType, filePath: clipboardPath)
            return
        }

        let beforeRowId = try await latestOutgoingMessageRowId()
        do {
            let lines = appleMessagesAttachmentScriptLines()
            let args = lines.flatMap { ["-e", $0] } + ["--", recipient, serviceType, filePath]
            _ = try await runner.run(osascriptCommand, args)
            try await verifyAttachmentSend(afterRowId: beforeRowId, originalFileName: URL(fileURLWithPath: filePath).lastPathComponent)
        } catch let fileSendError {
            throw fileSendError
        }
    }

    private func clipboardPreferredImagePath(from filePath: String) async throws -> String {
        let ext = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        if ext == "jpg" || ext == "jpeg" {
            return filePath
        }
        return try await createClipboardFriendlyJPEG(from: filePath) ?? filePath
    }

    private func sendClipboardImage(recipient: String, serviceType: String, filePath: String) async throws {
        let fallbackBeforeRowId = try await latestOutgoingMessageRowId()
        let lines = appleMessagesClipboardImageScriptLines()
        let args = lines.flatMap { ["-e", $0] } + ["--", recipient, serviceType, filePath]
        _ = try await runner.run(osascriptCommand, args)
        try await verifyAttachmentSend(afterRowId: fallbackBeforeRowId, originalFileName: nil)
    }

    private func createClipboardFriendlyJPEG(from filePath: String) async throws -> String? {
        let ext = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        guard ["png", "jpg", "jpeg", "tif", "tiff", "heic", "bmp", "webp"].contains(ext) else { return nil }
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MessagesCodexBridgeAttachments", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let output = directory.appendingPathComponent("\(UUID().uuidString).jpg")
        _ = try await runner.run("/usr/bin/sips", ["-s", "format", "jpeg", "-s", "formatOptions", "82", "-Z", "1600", filePath, "--out", output.path])
        guard FileManager.default.fileExists(atPath: output.path) else { return nil }
        return output.path
    }

    private func latestOutgoingMessageRowId() async throws -> Int64 {
        guard let messagesDbPath else { return 0 }
        let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", messagesDbPath, "SELECT COALESCE(MAX(ROWID), 0) FROM message WHERE is_from_me = 1;"])
        return Int64(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private func verifyAttachmentSend(afterRowId: Int64, originalFileName: String?) async throws {
        guard let messagesDbPath else { return }
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        let nameFilter: String
        if let originalFileName {
            let fileName = originalFileName.replacingOccurrences(of: "'", with: "''")
            nameFilter = "AND a.transfer_name = '\(fileName)'"
        } else {
            nameFilter = ""
        }
        let sql = """
        SELECT m.ROWID || '|' || COALESCE(m.error, 0) || '|' || COALESCE(a.transfer_state, 0) || '|' || COALESCE(m.date_delivered, 0)
        FROM message m
        JOIN message_attachment_join maj ON maj.message_id = m.ROWID
        JOIN attachment a ON a.ROWID = maj.attachment_id
        WHERE m.is_from_me = 1
          AND m.ROWID > \(afterRowId)
          \(nameFilter)
        ORDER BY m.ROWID DESC
        LIMIT 1;
        """
        let result = try await runner.run("/usr/bin/sqlite3", ["-readonly", messagesDbPath, sql])
        let fields = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|").map(String.init)
        guard fields.count == 4 else {
            throw StoreError.validation("Messages did not create an outgoing attachment row.")
        }
        let rowId = fields[0]
        let error = Int(fields[1]) ?? 0
        let transferState = Int(fields[2]) ?? 0
        let delivered = Int64(fields[3]) ?? 0
        if error != 0 || transferState == 6 || delivered == 0 {
            throw StoreError.validation("Messages created an outgoing attachment row \(rowId), but did not deliver it: error=\(error), transfer_state=\(transferState), date_delivered=\(delivered).")
        }
    }

    private func sendChunk(recipient: String, service: String, text: String) async throws {
        let serviceType = service.lowercased().contains("sms") ? "SMS" : "iMessage"
        let lines = [
            "on run argv",
            "set recipientHandle to item 1 of argv",
            "set serviceName to item 2 of argv",
            "set messageBody to item 3 of argv",
            "tell application \"Messages\"",
            "if serviceName is \"SMS\" then",
            "set targetService to 1st service whose service type = SMS",
            "else",
            "set targetService to 1st service whose service type = iMessage",
            "end if",
            "set targetBuddy to buddy recipientHandle of targetService",
            "send messageBody to targetBuddy",
            "end tell",
            "end run"
        ]
        let args = lines.flatMap { ["-e", $0] } + ["--", recipient, serviceType, text]
        _ = try await runner.run(osascriptCommand, args)
    }
}

public func appleMessagesAttachmentScriptLines() -> [String] {
    [
        "on run argv",
        "set recipientHandle to item 1 of argv",
        "set serviceName to item 2 of argv",
        "set attachmentPath to item 3 of argv",
        "set attachmentFile to POSIX file attachmentPath as alias",
        "tell application \"Messages\"",
        "if serviceName is \"SMS\" then",
        "set targetService to 1st service whose service type = SMS",
        "else",
        "set targetService to 1st service whose service type = iMessage",
        "end if",
        "set targetBuddy to buddy recipientHandle of targetService",
        "try",
        "send attachmentFile to targetBuddy",
        "on error buddyError number buddyErrorNumber",
        "set targetChat to missing value",
        "repeat with candidateChat in chats",
        "try",
        "if service type of account of candidateChat is service type of targetService then",
        "repeat with candidateParticipant in participants of candidateChat",
        "if handle of candidateParticipant is recipientHandle or id of candidateParticipant contains recipientHandle then",
        "set targetChat to candidateChat",
        "exit repeat",
        "end if",
        "end repeat",
        "end if",
        "end try",
        "if targetChat is not missing value then exit repeat",
        "end repeat",
        "if targetChat is missing value then error buddyError number buddyErrorNumber",
        "send attachmentFile to targetChat",
        "end try",
        "end tell",
        "end run"
    ]
}

public func appleMessagesClipboardImageScriptLines() -> [String] {
    [
        "on run argv",
        "set recipientHandle to item 1 of argv",
        "set serviceName to item 2 of argv",
        "set attachmentPath to item 3 of argv",
        "set imageFile to POSIX file attachmentPath",
        "set fileExtension to do shell script \"/usr/bin/python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).suffix.lower()[1:])' \" & quoted form of attachmentPath",
        "if fileExtension is \"png\" then",
        "set the clipboard to (read imageFile as «class PNGf»)",
        "else if fileExtension is \"jpg\" or fileExtension is \"jpeg\" then",
        "set the clipboard to (read imageFile as JPEG picture)",
        "else if fileExtension is \"gif\" then",
        "set the clipboard to (read imageFile as GIF picture)",
        "else if fileExtension is \"tif\" or fileExtension is \"tiff\" then",
        "set the clipboard to (read imageFile as TIFF picture)",
        "else",
        "set the clipboard to (read imageFile as «class PNGf»)",
        "end if",
        "if serviceName is \"SMS\" then",
        "open location \"sms:\" & recipientHandle",
        "else",
        "open location \"sms:\" & recipientHandle",
        "end if",
        "tell application \"Messages\" to activate",
        "delay 0.8",
        "tell application \"System Events\"",
        "tell process \"Messages\"",
        "set frontmost to true",
        "keystroke \"v\" using command down",
        "delay 0.8",
        "key code 36",
        "end tell",
        "end tell",
        "end run"
    ]
}

public struct OutgoingReply: Equatable, Sendable {
    public var text: String
    public var attachments: [String]
}

public func prepareOutgoingReply(_ text: String, config: BridgeConfig) -> OutgoingReply {
    prepareOutgoingReply(
        text,
        homeAccessRoot: config.homeAccessRoot,
        attachmentMode: config.effectiveOutgoingAttachmentMode,
        attachmentRoots: config.effectiveOutgoingAttachmentRoots,
        attachmentExtensions: config.effectiveOutgoingAttachmentExtensions
    )
}

public func prepareOutgoingReply(_ text: String, homeAccessRoot: String) -> OutgoingReply {
    prepareOutgoingReply(
        text,
        homeAccessRoot: homeAccessRoot,
        attachmentMode: "restricted",
        attachmentRoots: [
            homeAccessRoot,
            NSTemporaryDirectory(),
            "/tmp",
            "/private/tmp"
        ],
        attachmentExtensions: defaultOutgoingAttachmentExtensions()
    )
}

public func prepareOutgoingReply(
    _ text: String,
    homeAccessRoot: String,
    attachmentMode: String,
    attachmentRoots: [String],
    attachmentExtensions: [String]
) -> OutgoingReply {
    let markerPrefix = "BRIDGE_ATTACH:"
    var lines: [String] = []
    var attachments: [String] = []

    for line in text.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.range(of: markerPrefix, options: [.caseInsensitive, .anchored]) != nil {
            let rawPath = String(trimmed.dropFirst(markerPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let path = validOutgoingAttachmentPath(rawPath, mode: attachmentMode, roots: attachmentRoots, extensions: attachmentExtensions) {
                attachments.append(path)
            }
        } else {
            lines.append(line)
        }
    }

    var seen = Set<String>()
    let uniqueAttachments = attachments.filter { seen.insert($0).inserted }
    return OutgoingReply(text: lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), attachments: uniqueAttachments)
}

public func attachmentPathsMentioned(in text: String, homeAccessRoot: String) -> [String] {
    attachmentPathsMentioned(
        in: text,
        homeAccessRoot: homeAccessRoot,
        attachmentMode: "restricted",
        attachmentRoots: [
            homeAccessRoot,
            NSTemporaryDirectory(),
            "/tmp",
            "/private/tmp"
        ],
        attachmentExtensions: defaultOutgoingAttachmentExtensions()
    )
}

public func attachmentPathsMentioned(
    in text: String,
    homeAccessRoot: String,
    attachmentMode: String,
    attachmentRoots: [String],
    attachmentExtensions: [String]
) -> [String] {
    var results: [String] = []
    for candidate in directAttachmentPathCandidates(in: text) {
        if let path = validOutgoingAttachmentPath(candidate, mode: attachmentMode, roots: attachmentRoots, extensions: attachmentExtensions) {
            results.append(path)
        }
    }
    var searchStart = text.startIndex
    while let start = text.range(of: "/Users/", range: searchStart..<text.endIndex)?.lowerBound {
        guard let end = earliestAttachmentExtensionEnd(in: text, after: start) else { break }
        let raw = String(text[start..<end]).trimmingCharacters(in: CharacterSet(charactersIn: ".,;:)"))
        if let path = validOutgoingAttachmentPath(raw, mode: attachmentMode, roots: attachmentRoots, extensions: attachmentExtensions) {
            results.append(path)
        }
        searchStart = end
    }
    return results
}

private func directAttachmentPathCandidates(in text: String) -> [String] {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    var candidates = [trimmed]
    for separator in [": ", " at ", " here: ", " path: "] {
        if let range = trimmed.range(of: separator, options: [.caseInsensitive, .backwards]) {
            candidates.append(String(trimmed[range.upperBound...]))
        }
    }
    return candidates.map { candidate in
        candidate.trimmingCharacters(in: CharacterSet(charactersIn: " \t\r\n\"'`<>.,;:)"))
    }.filter { candidate in
        candidate.hasPrefix("/") || candidate.hasPrefix("~/")
    }
}

private func earliestAttachmentExtensionEnd(in text: String, after start: String.Index) -> String.Index? {
    let extensions = ["png", "jpg", "jpeg", "gif", "heic", "tif", "tiff", "bmp", "webp", "pdf"]
    return extensions
        .compactMap { ext -> String.Index? in
            text.range(of: ".\(ext)", options: [.caseInsensitive], range: start..<text.endIndex)?.upperBound
        }
        .min()
}

private func validOutgoingAttachmentPath(_ rawPath: String, mode: String, roots: [String], extensions: [String]) -> String? {
    let expanded = (rawPath as NSString).expandingTildeInPath
    let url = URL(fileURLWithPath: expanded).standardizedFileURL
    guard outgoingAttachmentPathIsAllowed(url.path, mode: mode, roots: roots),
          allowedOutgoingAttachmentExtension(url.pathExtension, extensions: extensions) else { return nil }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else { return nil }
    return url.path
}

private func outgoingAttachmentPathIsAllowed(_ path: String, mode: String, roots: [String]) -> Bool {
    if mode.localizedCaseInsensitiveCompare("fullAccess") == .orderedSame || mode.localizedCaseInsensitiveCompare("permissive") == .orderedSame {
        return path.hasPrefix("/")
    }
    return roots.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath).standardizedFileURL.path }.contains { root in
        path == root || path.hasPrefix(root.hasSuffix("/") ? root : root + "/")
    }
}

private func allowedOutgoingAttachmentExtension(_ ext: String, extensions: [String]) -> Bool {
    let allowed = Set(extensions.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased() })
    return allowed.contains("*") || allowed.contains(ext.lowercased())
}

private func isClipboardSendableImage(_ path: String) -> Bool {
    ["png", "jpg", "jpeg", "gif", "tif", "tiff", "heic", "bmp", "webp"].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
}
