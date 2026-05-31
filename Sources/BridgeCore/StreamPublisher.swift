import CryptoKit
import Foundation

public typealias StreamPublisherRunner = @Sendable (_ invocation: StreamPublishInvocation) async -> StreamPublishProcessResult
public typealias StreamPublishNPMResolver = @Sendable () async -> StreamPublishNPMResolution

public enum StreamPublishNPMResolution: Equatable, Sendable {
    case success(String)
    case failure(String)
}

public struct StreamPublishInvocation: Equatable, Sendable {
    public var cwd: String
    public var executable: String
    public var arguments: [String]
    public var eventJsonPath: String
    public var resultJsonPath: String

    public init(cwd: String, executable: String, arguments: [String], eventJsonPath: String, resultJsonPath: String) {
        self.cwd = cwd
        self.executable = executable
        self.arguments = arguments
        self.eventJsonPath = eventJsonPath
        self.resultJsonPath = resultJsonPath
    }
}

public struct StreamPublishProcessResult: Equatable, Sendable {
    public var stdout: String
    public var stderr: String
    public var exitCode: Int32

    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
}

public struct StreamPublishEventMedia: Codable, Equatable, Sendable {
    public var path: String
    public var mimeType: String
    public var alt: String

    public init(path: String, mimeType: String, alt: String = "") {
        self.path = path
        self.mimeType = mimeType
        self.alt = alt
    }
}

public struct StreamPublishResultSummary: Equatable, Sendable {
    public var success: Bool
    public var phase: String
    public var publicUrl: String?
    public var commitHash: String?
    public var crosspostSummary: String?
    public var errorSummary: String?
}

public enum StreamPublishMediaReadiness: Equatable, Sendable {
    case success([StreamPublishEventMedia])
    case failure(String)
}

public let streamPublishWebsiteRepoPath = "/Users/moss/Developer/urcad.es"
public let streamPublishDefaultPathValue = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
public let streamPublishPendingMediaTimeoutSeconds: TimeInterval = 600

public func isStreamPublishMessageText(_ text: String) -> Bool {
    text.hasPrefix("🎡")
}

public func isStreamPublishWaitingForMediaText(_ text: String) -> Bool {
    text.hasPrefix("🎡🎡")
}

public func streamPublishDisplayText(_ text: String) -> String {
    var body = text
    if body.hasPrefix("🎡🎡") {
        body.removeFirst(2)
    } else if body.hasPrefix("🎡") {
        body.removeFirst()
    }
    return body.trimmingCharacters(in: .whitespacesAndNewlines)
}

public func streamPublishCombinedEventId(textGuid: String, mediaMessage: MessageItem) -> String {
    let attachmentComponent = mediaMessage.attachments
        .map { String($0.attachmentId) }
        .joined(separator: "-")
    return [textGuid, mediaMessage.guid, attachmentComponent]
        .filter { !$0.isEmpty }
        .joined(separator: "+")
}

public func streamPublishInvocation(eventJsonPath: String, resultJsonPath: String, npmPath: String) -> StreamPublishInvocation {
    StreamPublishInvocation(
        cwd: streamPublishWebsiteRepoPath,
        executable: "/usr/bin/env",
        arguments: [
            "PATH=\(streamPublishPathValue(npmPath: npmPath))",
            npmPath, "run", "publish:stream:run", "--",
            "--event", eventJsonPath,
            "--result-json", resultJsonPath
        ],
        eventJsonPath: eventJsonPath,
        resultJsonPath: resultJsonPath
    )
}

public func streamPublishPathValue(npmPath: String) -> String {
    let npmBinDir = URL(fileURLWithPath: npmPath).deletingLastPathComponent().path
    let defaults = streamPublishDefaultPathValue.split(separator: ":").map(String.init)
    let parts = [npmBinDir] + defaults.filter { $0 != npmBinDir }
    return parts.joined(separator: ":")
}

public func resolveStreamPublisherNPMPath() async -> StreamPublishNPMResolution {
    let shellResult = await runStreamPublisherResolverCommand(
        executable: "/bin/zsh",
        arguments: ["-lc", "command -v npm"]
    )
    if shellResult.exitCode == 0,
       let npmPath = shellResult.stdout
        .split(whereSeparator: \.isNewline)
        .map(String.init)
        .first(where: { !$0.isEmpty }),
       FileManager.default.isExecutableFile(atPath: npmPath) {
        return .success(npmPath)
    }

    for candidate in nvmNPMCandidates(homeDir: NSHomeDirectory()) where FileManager.default.isExecutableFile(atPath: candidate) {
        return .success(candidate)
    }

    let resolverOutput = [shellResult.stderr, shellResult.stdout]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n")
    let detail = resolverOutput.isEmpty ? "no output" : sanitizedTail(resolverOutput, maxLength: 1_000)
    return .failure("npm not found from /bin/zsh -lc 'command -v npm'; checked NVM installs under \(NSHomeDirectory())/.nvm/versions/node; resolver output: \(detail)")
}

public func streamPublishEventPaths(paths: RuntimePaths, guid: String) -> (eventJson: URL, resultJson: URL) {
    let directory = paths.tmpDir.appendingPathComponent("stream-events", isDirectory: true)
    let name = sanitizedStreamPublishFilenameComponent(guid)
    return (
        directory.appendingPathComponent("\(name).json"),
        directory.appendingPathComponent("\(name).result.json")
    )
}

public func streamPublishRawTextHash(_ text: String) -> String {
    let digest = SHA256.hash(data: Data(text.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}

public func writeStreamPublishEvent(message: MessageItem, media: [StreamPublishEventMedia], eventJson: URL, eventId: String? = nil) throws {
    struct Event: Codable {
        var id: String
        var source: String
        var sender: String
        var receivedAt: String
        var text: String
        var media: [StreamPublishEventMedia]
    }
    try FileManager.default.createDirectory(at: eventJson.deletingLastPathComponent(), withIntermediateDirectories: true)
    let event = Event(
        id: eventId ?? message.guid,
        source: "imessage",
        sender: message.handleId,
        receivedAt: message.receivedAt ?? DateCodec.iso(),
        text: message.text,
        media: media
    )
    let data = try JSONEncoder.pretty.encode(event)
    try data.write(to: eventJson, options: .atomic)
}

public func waitForStableStreamPublishMedia(
    attachments: [AttachmentRef],
    timeoutSeconds: TimeInterval = 600,
    stableDelayNanoseconds: UInt64 = 1_000_000_000
) async -> StreamPublishMediaReadiness {
    var media: [StreamPublishEventMedia] = []
    for attachment in attachments {
        guard isSupportedStreamPublishMedia(attachment) else {
            return .failure("Unsupported attachment \(attachment.transferName ?? String(attachment.attachmentId)) with type \(attachment.mimeType ?? attachment.uti ?? attachment.kind). Only image and video media are supported.")
        }
        guard let absolutePath = attachment.absolutePath, !absolutePath.isEmpty else {
            return .failure("Attachment \(attachment.transferName ?? String(attachment.attachmentId)) has no local file path.")
        }
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        var stable = false
        while Date() < deadline {
            guard let firstSize = fileSize(at: absolutePath) else {
                try? await Task.sleep(nanoseconds: stableDelayNanoseconds)
                continue
            }
            try? await Task.sleep(nanoseconds: stableDelayNanoseconds)
            guard let secondSize = fileSize(at: absolutePath) else {
                continue
            }
            if firstSize == secondSize {
                stable = true
                break
            }
        }
        guard stable else {
            return .failure("Timed out waiting for attachment \(attachment.transferName ?? absolutePath) to exist and remain stable.")
        }
        media.append(StreamPublishEventMedia(path: absolutePath, mimeType: streamPublishMimeType(attachment)))
    }
    return .success(media)
}

public func runStreamPublisherProcess(_ invocation: StreamPublishInvocation) async -> StreamPublishProcessResult {
    await Task.detached {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: invocation.executable)
        process.arguments = invocation.arguments
        process.currentDirectoryURL = URL(fileURLWithPath: invocation.cwd)
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        do {
            try process.run()
        } catch {
            return StreamPublishProcessResult(stdout: "", stderr: "Failed to start \(invocation.executable): \(error.localizedDescription)", exitCode: 127)
        }
        process.waitUntilExit()
        let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return StreamPublishProcessResult(stdout: stdoutText, stderr: stderrText, exitCode: process.terminationStatus)
    }.value
}

private func runStreamPublisherResolverCommand(executable: String, arguments: [String]) async -> StreamPublishProcessResult {
    await Task.detached {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        do {
            try process.run()
        } catch {
            return StreamPublishProcessResult(stdout: "", stderr: "Failed to start \(executable): \(error.localizedDescription)", exitCode: 127)
        }
        process.waitUntilExit()
        let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return StreamPublishProcessResult(stdout: stdoutText, stderr: stderrText, exitCode: process.terminationStatus)
    }.value
}

public func parseStreamPublishResult(resultJsonPath: String, processResult: StreamPublishProcessResult) -> StreamPublishResultSummary {
    let stdout = sanitizedTail(processResult.stdout)
    let stderr = sanitizedTail(processResult.stderr)
    guard FileManager.default.fileExists(atPath: resultJsonPath),
          let data = try? Data(contentsOf: URL(fileURLWithPath: resultJsonPath)),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        let phase = processResult.exitCode == 0 ? "result_json" : "wrapper"
        let error = [stderr, stdout].filter { !$0.isEmpty }.joined(separator: "\n")
        return StreamPublishResultSummary(success: false, phase: phase, publicUrl: nil, commitHash: nil, crosspostSummary: nil, errorSummary: error.isEmpty ? "Publisher did not write result JSON." : error)
    }
    let publicUrl = firstString(object, keys: ["publicUrl", "url", "finalUrl"])
    let commitHash = firstString(object, keys: ["commitHash", "commit", "hash", "shortHash"])
    let crosspostSummary = streamPublishCrosspostSummary(object["crossposts"])
    let phase = firstString(object, keys: ["phase", "failedPhase"]) ?? (processResult.exitCode == 0 ? "verify" : "wrapper")
    let explicitSuccess = object["success"] as? Bool
    let status = (object["status"] as? String)?.lowercased()
    let inferredSuccess = ["success", "succeeded", "ok"].contains(status ?? "") || (processResult.exitCode == 0 && publicUrl != nil)
    let success = explicitSuccess ?? inferredSuccess
    if success, let publicUrl {
        return StreamPublishResultSummary(success: true, phase: phase, publicUrl: publicUrl, commitHash: commitHash, crosspostSummary: crosspostSummary, errorSummary: nil)
    }
    let resultError = firstString(object, keys: ["error", "message", "failureReason", "summary"])
    let error = [resultError, stderr, stdout].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
    return StreamPublishResultSummary(success: false, phase: phase, publicUrl: publicUrl, commitHash: commitHash, crosspostSummary: crosspostSummary, errorSummary: sanitizedTail(error.isEmpty ? "Publisher failed without an error message." : error))
}

private func streamPublishCrosspostSummary(_ value: Any?) -> String? {
    guard let crossposts = value as? [String: Any] else { return nil }
    let targets = [
        (key: "bluesky", label: "Bluesky"),
        (key: "arena", label: "Are.na"),
        (key: "gotosocial", label: "GoToSocial")
    ]
    let parts = targets.compactMap { target -> String? in
        guard let result = crossposts[target.key] as? [String: Any] else { return nil }
        return "\(target.label) \(streamPublishCrosspostStatus(result))"
    }
    guard !parts.isEmpty else { return nil }
    return "Cross-posts: \(parts.joined(separator: ", "))"
}

private func streamPublishCrosspostStatus(_ result: [String: Any]) -> String {
    if boolValue(result["skipped"]) == true {
        return "skipped"
    }
    if boolValue(result["ok"]) == true {
        return "ok"
    }
    if let error = firstString(result, keys: ["error", "message"]),
       let code = firstHTTPStatusCode(in: error) {
        return "failed (\(code))"
    }
    return "failed"
}

private func boolValue(_ value: Any?) -> Bool? {
    if let bool = value as? Bool { return bool }
    if let number = value as? NSNumber { return number.boolValue }
    return nil
}

private func firstHTTPStatusCode(in value: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: #"\b[45][0-9]{2}\b"#) else { return nil }
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    guard let match = regex.firstMatch(in: value, range: range),
          let matchRange = Range(match.range, in: value) else {
        return nil
    }
    return String(value[matchRange])
}

public func sanitizedTail(_ value: String, maxLength: Int = 4_000) -> String {
    var redacted = value
    let patterns = [
        #"(?i)(authorization:\s*bearer\s+)[^\s]+"#,
        #"(?i)\b((?:cf_)?(?:api_)?(?:token|secret|password|key))=([^\s]+)"#
    ]
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(redacted.startIndex..<redacted.endIndex, in: redacted)
            if pattern.contains("authorization") {
                redacted = regex.stringByReplacingMatches(in: redacted, range: range, withTemplate: "$1[redacted]")
            } else {
                redacted = regex.stringByReplacingMatches(in: redacted, range: range, withTemplate: "$1=[redacted]")
            }
        }
    }
    if redacted.count <= maxLength { return redacted }
    return String(redacted.suffix(maxLength))
}

private func sanitizedStreamPublishFilenameComponent(_ guid: String) -> String {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    let safeScalars = guid.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
    let safe = String(safeScalars).trimmingCharacters(in: CharacterSet(charactersIn: "._-"))
    let prefix = safe.isEmpty ? "message" : String(safe.prefix(80))
    return "\(prefix)-\(streamPublishRawTextHash(guid).prefix(12))"
}

private func nvmNPMCandidates(homeDir: String) -> [String] {
    let versionsDir = URL(fileURLWithPath: homeDir)
        .appendingPathComponent(".nvm/versions/node", isDirectory: true)
    guard let versions = try? FileManager.default.contentsOfDirectory(at: versionsDir, includingPropertiesForKeys: nil) else {
        return []
    }
    return versions
        .filter { $0.hasDirectoryPath }
        .sorted { $0.lastPathComponent > $1.lastPathComponent }
        .map { $0.appendingPathComponent("bin/npm").path }
}

private func isSupportedStreamPublishMedia(_ attachment: AttachmentRef) -> Bool {
    let mime = (attachment.mimeType ?? "").lowercased()
    return attachment.kind == "image" || attachment.kind == "video" || mime.hasPrefix("image/") || mime.hasPrefix("video/")
}

private func streamPublishMimeType(_ attachment: AttachmentRef) -> String {
    if let mimeType = attachment.mimeType, !mimeType.isEmpty {
        return mimeType
    }
    let ext = attachment.absolutePath.map { URL(fileURLWithPath: $0).pathExtension.lowercased() } ?? ""
    switch ext {
    case "jpg", "jpeg": return "image/jpeg"
    case "png": return "image/png"
    case "gif": return "image/gif"
    case "webp": return "image/webp"
    case "heic": return "image/heic"
    case "mov": return "video/quicktime"
    case "mp4": return "video/mp4"
    case "m4v": return "video/x-m4v"
    default: return attachment.kind == "video" ? "video/quicktime" : "image/jpeg"
    }
}

private func fileSize(at path: String) -> UInt64? {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
          let size = attrs[.size] as? NSNumber else {
        return nil
    }
    return size.uint64Value
}

private func firstString(_ object: [String: Any], keys: [String]) -> String? {
    for key in keys {
        if let value = object[key] as? String, !value.isEmpty {
            return value
        }
    }
    return nil
}
