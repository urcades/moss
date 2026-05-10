import Foundation

public func buildBatchPreview(_ batch: PendingBatch) -> String {
    let joined = batch.items.map { item in
        if !item.text.isEmpty { return item.text }
        return item.attachments.first?.transferName ?? "(attachment only)"
    }.joined(separator: " / ")
    return String(joined.prefix(120))
}

public func buildPromptRequest(from batch: PendingBatch) -> PromptRequest {
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

    return PromptRequest(promptText: lines.joined(separator: "\n"), attachments: attachments)
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
