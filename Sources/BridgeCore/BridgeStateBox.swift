import Foundation

public final class BridgeStateBox: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var value: BridgeState

    public init(_ value: BridgeState) {
        self.value = value
    }

    public func snapshot() -> BridgeState {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    public func replace(_ value: BridgeState) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    @discardableResult
    public func mutate<T>(_ update: (inout BridgeState) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try update(&value)
    }
}
