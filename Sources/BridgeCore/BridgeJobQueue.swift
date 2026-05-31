import Foundation

public enum BridgeJob: Sendable {
    case localCommand(String, MessageItem)
    case interactiveCallbackReply(MessageItem)
    case streamPublish(MessageItem)
    case promptBatch(PendingBatch)

    var canRunDuringActiveJob: Bool {
        switch self {
        case .localCommand, .interactiveCallbackReply:
            return true
        case .streamPublish:
            return false
        case .promptBatch:
            return false
        }
    }
}

public final class BridgeJobQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var jobs: [BridgeJob] = []

    public init() {}

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return jobs.isEmpty
    }

    public func enqueueLocalCommand(_ command: String, _ message: MessageItem) {
        enqueue(.localCommand(command, message))
    }

    public func enqueueInteractiveCallbackReply(_ message: MessageItem) {
        enqueue(.interactiveCallbackReply(message))
    }

    public func enqueueStreamPublish(_ message: MessageItem) {
        enqueue(.streamPublish(message))
    }

    public func enqueuePromptBatch(_ batch: PendingBatch) {
        enqueue(.promptBatch(batch))
    }

    public func enqueue(_ job: BridgeJob) {
        lock.lock()
        jobs.append(job)
        lock.unlock()
    }

    public func dequeueNext(hasActiveJob: Bool) -> BridgeJob? {
        lock.lock()
        defer { lock.unlock() }
        guard !jobs.isEmpty else { return nil }
        let index: Int
        if hasActiveJob {
            guard let cutThroughIndex = jobs.firstIndex(where: { $0.canRunDuringActiveJob }) else {
                return nil
            }
            index = cutThroughIndex
        } else {
            index = 0
        }
        return jobs.remove(at: index)
    }
}
