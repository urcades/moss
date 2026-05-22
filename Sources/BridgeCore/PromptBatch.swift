import Foundation

public func buildBatchPreview(_ batch: PendingBatch) -> String {
    let joined = batch.items.map { item in
        if !item.text.isEmpty { return item.text }
        return item.attachments.first?.transferName ?? "(attachment only)"
    }.joined(separator: " / ")
    return String(joined.prefix(120))
}

public func promptLooksLikeCodexAutomationRequest(_ text: String) -> Bool {
    let normalized = canonicalPromptText(text)
    if promptExplicitlyTargetsBridgeSource(normalized) {
        return false
    }
    if automationCreationIntentScore(text) > 0 {
        return true
    }
    let automationTerms = [
        "automation",
        "automations",
        "reminder",
        "reminders",
        "recurring",
        "scheduled",
        "monitor",
        "watch",
        "check back",
        "follow up"
    ]
    if automationTerms.contains(where: { containsPhrase(normalized, $0) }) {
        return true
    }
    if containsPhrase(normalized, "schedule") {
        let scheduledTaskTerms = ["automation", "reminder", "task", "job", "run", "check", "message", "send", "tell me", "follow up"]
        return scheduledTaskTerms.contains { containsPhrase(normalized, $0) }
    }
    return false
}

private func promptExplicitlyTargetsBridgeSource(_ normalized: String) -> Bool {
    let bridgeTerms = ["bridge", "messages bridge", "moss", "helper"]
    let sourceTerms = ["source", "code", "swift", "implementation", "implement", "modify", "edit", "change", "patch"]
    return bridgeTerms.contains { containsPhrase(normalized, $0) } &&
        sourceTerms.contains { containsPhrase(normalized, $0) }
}

func automationCreationIntentScore(_ text: String) -> Int {
    let normalized = canonicalPromptText(text)
    if containsAnyPattern(text, [
        #"(?i)\b(create|make|add|set\s*up|setup|start)\b.{0,80}\b(automation|automations|reminder|reminders|recurring task|scheduled task|monitor|watch)\b"#,
        #"(?i)\b(new)\b.{0,40}\b(automation|reminder|recurring task|scheduled task)\b"#,
        #"(?i)\b(automation|reminder)\b.{0,60}\b(create|make|add|set\s*up|setup|start|new)\b"#
    ]) {
        return 3
    }
    if ["remind me", "check back", "follow up with me", "follow up on", "monitor", "watch"].contains(where: { containsPhrase(normalized, $0) }) {
        return 2
    }
    if containsAnyPattern(text, [
        #"(?i)\bschedule\b.{0,80}\b(automation|reminder|task|job|run|check|message|send|tell me|follow[- ]?up)\b"#,
        #"(?i)\b(recurring|daily|weekly|monthly|every\s+(morning|afternoon|evening|day|week|month|hour))\b.{0,80}\b(send|tell me|notify me|check|summarize|digest)\b"#
    ]) {
        return 1
    }
    return 0
}

func canonicalPromptText(_ text: String) -> String {
    let lowered = text.lowercased()
    let scalars = lowered.unicodeScalars.map { scalar -> Character in
        CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
    }
    return String(scalars).split(whereSeparator: \.isWhitespace).joined(separator: " ")
}

func containsPhrase(_ canonicalText: String, _ phrase: String) -> Bool {
    let canonicalPhrase = canonicalPromptText(phrase)
    guard !canonicalPhrase.isEmpty else { return false }
    return " \(canonicalText) ".contains(" \(canonicalPhrase) ")
}

func containsAnyPattern(_ text: String, _ patterns: [String]) -> Bool {
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return patterns.contains { pattern in
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: text, range: range) != nil
    }
}

public func buildPromptRequest(from batch: PendingBatch) -> PromptRequest {
    buildPromptRequest(from: batch, recentMediaRefs: [])
}

public func buildPromptRequest(from batch: PendingBatch, recentMediaRefs: [RecentMediaRef]) -> PromptRequest {
    var lines = [
        "These Apple Messages arrived within one short window. Interpret them as a single prompt.",
        "Preserve chronological order and the combined intent across all message parts.",
        "Image attachments are passed in as Codex image inputs. Other attachments are listed with local paths when available; inspect or read them when they are relevant to the request."
    ]
    var attachments: [AttachmentRef] = []

    for (index, item) in batch.items.enumerated() {
        lines.append("")
        lines.append("Message \(index + 1):")
        lines.append(item.text.isEmpty ? "(attachment only)" : item.text)
        guard !item.attachments.isEmpty else { continue }
        lines.append("Attachments:")
        for attachment in item.attachments {
            let refreshed = refreshAttachment(attachment)
            lines.append(describeAttachment(refreshed))
            attachments.append(refreshed)
        }
    }

    let combinedText = batch.items.map(\.text).joined(separator: "\n")
    if batch.items.allSatisfy({ $0.attachments.isEmpty }),
       promptReferencesPreviousImage(combinedText),
       let recent = latestUsableImageRef(for: batch.handleId, service: batch.service, recentMediaRefs: recentMediaRefs) {
        let attachment = AttachmentRef(
            attachmentId: Int64(abs(recent.path.hashValue)),
            transferName: recent.transferName ?? URL(fileURLWithPath: recent.path).lastPathComponent,
            mimeType: mimeTypeForImagePath(recent.path),
            uti: nil,
            absolutePath: recent.path,
            kind: "image",
            exists: true
        )
        lines.append("")
        lines.append("Bridge media context:")
        lines.append("The user appears to refer to the most recent image in this Messages chat. Attach that image as the source image for this follow-up.")
        lines.append(describeAttachment(attachment))
        attachments.append(attachment)
    }

    if promptLooksLikeCodexAutomationRequest(batch.items.map(\.text).joined(separator: "\n")) {
        lines.insert("""
        Bridge routing guard:
        This user is asking Codex to use an automation, reminder, scheduling, monitoring, or follow-up capability on this Mac. Do not implement, modify, inspect, or continue any Messages bridge scheduler or daily digest code. Do not use memory entries about bridge daily digest scaffolds as instructions. If a Codex automation tool is available, use it. If no such tool is available in this Messages-launched turn, reply plainly that the automation cannot be created from here.

        """, at: 0)
    }

    return PromptRequest(promptText: lines.joined(separator: "\n"), attachments: attachments, threadName: buildBatchPreview(batch))
}

public func promptReferencesPreviousImage(_ text: String) -> Bool {
    let normalized = text.lowercased()
    let imageTerms = ["that image", "this image", "that picture", "this picture", "modify it", "edit it", "change it", "use it"]
    return imageTerms.contains { normalized.contains($0) }
}

public func latestUsableImageRef(for handleId: String, service: String, recentMediaRefs: [RecentMediaRef]) -> RecentMediaRef? {
    recentMediaRefs.reversed().first { ref in
        ref.handleId == handleId &&
            ref.service == service &&
            ref.kind == "image" &&
            ref.exists &&
            FileManager.default.fileExists(atPath: ref.path)
    }
}

private func mimeTypeForImagePath(_ path: String) -> String {
    switch URL(fileURLWithPath: path).pathExtension.lowercased() {
    case "jpg", "jpeg": return "image/jpeg"
    case "gif": return "image/gif"
    case "heic": return "image/heic"
    case "tif", "tiff": return "image/tiff"
    case "webp": return "image/webp"
    default: return "image/png"
    }
}

private func refreshAttachment(_ attachment: AttachmentRef) -> AttachmentRef {
    var copy = attachment
    copy.exists = attachment.absolutePath.map { FileManager.default.fileExists(atPath: $0) } ?? false
    return copy
}

private func describeAttachment(_ attachment: AttachmentRef) -> String {
    let displayName = attachment.transferName ?? attachment.absolutePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "attachment-\(attachment.attachmentId)"
    let mimeLabel = attachment.mimeType ?? attachment.uti ?? "unknown type"
    let location = attachment.absolutePath ?? "(no local file path)"
    var notes: [String] = []
    if attachment.kind == "unsupported" { notes.append("unsupported attachment type") }
    if !attachment.exists { notes.append("file missing on disk") }
    return "- \(displayName) (\(mimeLabel)) at \(location)\(notes.isEmpty ? "" : " [\(notes.joined(separator: "; "))]")"
}

public extension PromptRequest {
    func withPermissionRecoveryInstructions() -> PromptRequest {
        var copy = self
        copy.promptText += """

        Bridge note: a local macOS permission prompt was handled after the previous attempt stopped. Continue the original task from where it left off. If the same permission prompt is still blocking you, report the exact blocker once using BRIDGE_BLOCKED:.
        """
        return copy
    }
}
