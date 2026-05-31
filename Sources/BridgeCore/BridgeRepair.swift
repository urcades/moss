import Foundation

public struct BridgeRepairOptions: Equatable, Sendable {
    public var dryRun: Bool
    public var replay: Bool
    public var maxReplay: Int
    public var reloadLaunchAgents: Bool

    public init(dryRun: Bool = false, replay: Bool = true, maxReplay: Int = 50, reloadLaunchAgents: Bool = true) {
        self.dryRun = dryRun
        self.replay = replay
        self.maxReplay = max(0, maxReplay)
        self.reloadLaunchAgents = reloadLaunchAgents
    }
}

public struct MissedMessageReplayPlan: Equatable, Sendable {
    public var recoverableRows: [Int64]
    public var missedRows: [Int64]
    public var replayRows: [Int64]
    public var replayBatch: PendingBatch?
}

public struct BridgeRepairReport: Equatable, Sendable {
    public var dryRun: Bool
    public var staleJobRecovered: Bool
    public var staleJobThreadId: String?
    public var staleJobTurnId: String?
    public var helperLaunchAgentState: LaunchAgentLoadState
    public var permissionBrokerLaunchAgentState: LaunchAgentLoadState
    public var missedMessageRowIds: [Int64]
    public var replayRowIds: [Int64]
    public var replayStaged: Bool
    public var cursorAdvancedTo: Int64?
    public var reloadError: String?
    public var summary: String
}

public typealias LaunchAgentStateProvider = () async -> (LaunchAgentLoadState, LaunchAgentLoadState)
public typealias LaunchAgentReloader = () async throws -> Void
public typealias ProcessRunningChecker = (Int32) -> Bool

public func runBridgeRepair(
    paths: RuntimePaths = .current(),
    stores: RuntimeStores? = nil,
    options: BridgeRepairOptions = BridgeRepairOptions(),
    makeSource: ((BridgeConfig) -> MessageSource)? = nil,
    processIsRunning: ProcessRunningChecker = { pid in kill(pid, 0) == 0 },
    launchAgentStateProvider: LaunchAgentStateProvider? = nil,
    reloadLaunchAgents: LaunchAgentReloader? = nil
) async throws -> BridgeRepairReport {
    try ensureRuntimeDirectories(paths)
    let stores = stores ?? RuntimeStores(paths: paths)
    let config = try stores.config.load()
    let source = makeSource?(config) ?? SQLiteMessageSource(dbPath: config.messagesDbPath, trustedSenders: config.effectiveTrustedSenders)
    let lifecycle = ServiceLifecycle(paths: paths)
    let stateProvider = launchAgentStateProvider ?? {
        await (lifecycle.helperLaunchAgentState(), lifecycle.permissionBrokerLaunchAgentState())
    }
    let reloader = reloadLaunchAgents ?? {
        try await lifecycle.startHelperLaunchAgent()
    }

    let originalState = try stores.state.load()
    let staleJob = staleActiveJob(in: originalState, processIsRunning: processIsRunning)
    let missedMessages = try await source.fetchNewMessages(afterRowId: originalState.lastProcessedRowId)
    let replayPlan = buildMissedMessageReplayPlan(
        recoverableBatch: staleJob?.recoverableBatch,
        missedMessages: missedMessages,
        maxMissedRows: options.maxReplay
    )
    let launchStates = await stateProvider()

    var replayStaged = false
    var cursorAdvancedTo: Int64?
    var reloadError: String?
    if !options.dryRun {
        var next = originalState
        if let staleJob {
            next.activeJob = nil
            next.lastRecoverablePromptBatch = staleJob.recoverableBatch
        }
        if options.replay {
            next.pendingBatch = replayPlan.replayBatch
            replayStaged = replayPlan.replayBatch != nil
            if replayStaged {
                next.lastRecoverablePromptBatch = nil
            }
        }
        if let last = replayPlan.replayBatch?.items.last ?? missedMessages.last {
            next.lastProcessedRowId = last.rowId
            next.lastProcessedGuid = last.guid
            cursorAdvancedTo = last.rowId
        }
        try stores.state.save(next)
        if options.reloadLaunchAgents {
            do {
                try await reloader()
            } catch {
                reloadError = String(describing: error)
            }
        }
    }

    let report = BridgeRepairReport(
        dryRun: options.dryRun,
        staleJobRecovered: staleJob != nil,
        staleJobThreadId: staleJob?.codexSessionId,
        staleJobTurnId: staleJob?.codexTurnId,
        helperLaunchAgentState: launchStates.0,
        permissionBrokerLaunchAgentState: launchStates.1,
        missedMessageRowIds: missedMessages.map(\.rowId),
        replayRowIds: replayPlan.replayRows,
        replayStaged: replayStaged,
        cursorAdvancedTo: cursorAdvancedTo,
        reloadError: reloadError,
        summary: bridgeRepairSummaryText(
            dryRun: options.dryRun,
            staleJob: staleJob,
            helperState: launchStates.0,
            brokerState: launchStates.1,
            missedRows: missedMessages.map(\.rowId),
            replayRows: replayPlan.replayRows,
            replayStaged: replayStaged,
            cursorAdvancedTo: cursorAdvancedTo,
            reloadError: reloadError
        )
    )
    return report
}

public func buildMissedMessageReplayPlan(
    recoverableBatch: PendingBatch?,
    missedMessages: [MessageItem],
    maxMissedRows: Int
) -> MissedMessageReplayPlan {
    let boundedMissed = Array(missedMessages.prefix(max(0, maxMissedRows)))
    var seen = Set<String>()
    var replayItems: [MessageItem] = []
    for item in (recoverableBatch?.items ?? []) + boundedMissed {
        guard seen.insert(item.guid).inserted else { continue }
        replayItems.append(item)
    }
    let batch = replayItems.isEmpty ? nil : PendingBatch(
        handleId: replayItems.first?.handleId ?? recoverableBatch?.handleId ?? "",
        service: replayItems.first?.service ?? recoverableBatch?.service ?? "iMessage",
        startedAt: replayItems.first?.receivedAt ?? DateCodec.iso(),
        deadlineAt: "1970-01-01T00:00:00.000Z",
        items: replayItems
    )
    return MissedMessageReplayPlan(
        recoverableRows: recoverableBatch?.items.map(\.rowId) ?? [],
        missedRows: boundedMissed.map(\.rowId),
        replayRows: replayItems.map(\.rowId),
        replayBatch: batch
    )
}

private func staleActiveJob(in state: BridgeState, processIsRunning: ProcessRunningChecker) -> ActiveJob? {
    guard let job = state.activeJob, let pid = job.codexPid else { return nil }
    return processIsRunning(pid) ? nil : job
}

public func bridgeRepairSummaryText(
    dryRun: Bool,
    staleJob: ActiveJob?,
    helperState: LaunchAgentLoadState,
    brokerState: LaunchAgentLoadState,
    missedRows: [Int64],
    replayRows: [Int64],
    replayStaged: Bool,
    cursorAdvancedTo: Int64?,
    reloadError: String?
) -> String {
    var lines = ["Messages bridge repair\(dryRun ? " dry run" : ""):"]
    if let staleJob {
        lines.append("Stale active job: recovered thread \(staleJob.codexSessionId ?? "none") turn \(staleJob.codexTurnId ?? "none") row \(staleJob.rowId.map(String.init) ?? "none")")
    } else {
        lines.append("Stale active job: none")
    }
    lines.append("Helper LaunchAgent: \(helperState.statusText)")
    lines.append("Permission broker LaunchAgent: \(brokerState.statusText)")
    lines.append("Missed rows: \(missedRows.isEmpty ? "none" : missedRows.map(String.init).joined(separator: ", "))")
    lines.append("Replay rows: \(replayRows.isEmpty ? "none" : replayRows.map(String.init).joined(separator: ", "))")
    if !dryRun {
        lines.append("Replay staged: \(replayStaged ? "yes" : "no")")
        lines.append("Cursor advanced to: \(cursorAdvancedTo.map(String.init) ?? "unchanged")")
        lines.append("LaunchAgent reload: \(reloadError.map { "failed: \($0)" } ?? "requested")")
    }
    return lines.joined(separator: "\n")
}
