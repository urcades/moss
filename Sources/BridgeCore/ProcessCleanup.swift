import Foundation

public struct ProcessCleanupResult: Equatable, Sendable {
    public var rootPid: Int32
    public var terminatedPids: [Int32]

    public init(rootPid: Int32, terminatedPids: [Int32]) {
        self.rootPid = rootPid
        self.terminatedPids = terminatedPids
    }
}

public func descendantProcessIds(of pid: Int32, runner: ProcessRunner = ProcessRunner()) -> [Int32] {
    let output = (try? runner.runSync("/usr/bin/pgrep", ["-P", "\(pid)"])) ?? ""
    let children = output
        .split(whereSeparator: \.isNewline)
        .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    return children.flatMap { descendantProcessIds(of: $0, runner: runner) + [$0] }
}

@discardableResult
public func terminateProcessTree(rootPid: Int32, runner: ProcessRunner = ProcessRunner()) -> ProcessCleanupResult {
    let descendants = descendantProcessIds(of: rootPid, runner: runner)
    for pid in descendants {
        _ = try? runner.runSync("/bin/kill", ["-TERM", "\(pid)"])
    }
    _ = try? runner.runSync("/bin/kill", ["-TERM", "\(rootPid)"])
    return ProcessCleanupResult(rootPid: rootPid, terminatedPids: descendants + [rootPid])
}
