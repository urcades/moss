import Foundation

extension BridgeState {
    mutating func appendPendingBatchMessage(
        _ message: MessageItem,
        batchWindowMs: Int,
        messageDate: Date
    ) -> PendingBatch? {
        let deadline = DateCodec.iso(messageDate.addingTimeInterval(Double(batchWindowMs) / 1000))
        guard var pendingBatch else {
            self.pendingBatch = PendingBatch(
                handleId: message.handleId,
                service: message.service,
                startedAt: DateCodec.iso(messageDate),
                deadlineAt: deadline,
                items: [message]
            )
            return nil
        }
        if let currentDeadline = DateCodec.parse(pendingBatch.deadlineAt), messageDate > currentDeadline {
            let finalized = pendingBatch
            self.pendingBatch = PendingBatch(
                handleId: message.handleId,
                service: message.service,
                startedAt: DateCodec.iso(messageDate),
                deadlineAt: deadline,
                items: [message]
            )
            return finalized
        }
        pendingBatch.items.append(message)
        pendingBatch.deadlineAt = deadline
        self.pendingBatch = pendingBatch
        return nil
    }

    mutating func finalizePendingBatchForQueue() -> PendingBatch? {
        guard let batch = pendingBatch else { return nil }
        pendingBatch = nil
        return batch
    }

    mutating func takeLastRecoverablePromptBatch(for message: MessageItem) -> PendingBatch? {
        guard let batch = lastRecoverablePromptBatch,
              batch.handleId == message.handleId,
              batch.service == message.service else {
            return nil
        }
        lastRecoverablePromptBatch = nil
        pendingBatch = nil
        return batch
    }

    mutating func setLastRecoverablePromptBatch(_ batch: PendingBatch?) {
        lastRecoverablePromptBatch = batch
    }

    mutating func setPendingInteractiveCallback(_ callback: PendingInteractiveCallback) {
        pendingInteractiveCallback = callback
    }

    mutating func clearPendingInteractiveCallback() {
        pendingInteractiveCallback = nil
    }

    mutating func markPendingInteractiveCallbackAnswered(message: MessageItem, answeredAt: String) -> PendingInteractiveCallback? {
        guard var callback = pendingInteractiveCallback, callback.status == "pending" else { return nil }
        callback.status = "answered"
        callback.responseText = message.text
        callback.responseRowId = message.rowId
        callback.responseGuid = message.guid
        callback.answeredAt = answeredAt
        pendingInteractiveCallback = callback
        return callback
    }

    mutating func markPendingInteractiveCallbackExpired(now: Date) -> PendingInteractiveCallback? {
        guard var callback = pendingInteractiveCallback,
              callback.status == "pending",
              let expiresAt = callback.expiresAt,
              let deadline = DateCodec.parse(expiresAt),
              deadline <= now else {
            return nil
        }
        callback.status = "timedOut"
        callback.failureText = "Timed out waiting for a Messages reply."
        pendingInteractiveCallback = callback
        return callback
    }

    mutating func markPendingInteractiveCallbackFinished(callbackId: String, status: String, failureText: String?) -> PendingInteractiveCallback? {
        guard var callback = pendingInteractiveCallback, callback.callbackId == callbackId else { return nil }
        callback.status = status
        callback.failureText = failureText
        pendingInteractiveCallback = callback
        return callback
    }

    mutating func cancelPendingInteractiveCallback(failureText: String) -> Bool {
        guard var callback = pendingInteractiveCallback, callback.status == "pending" else { return false }
        callback.status = "canceled"
        callback.failureText = failureText
        pendingInteractiveCallback = callback
        return true
    }
}
