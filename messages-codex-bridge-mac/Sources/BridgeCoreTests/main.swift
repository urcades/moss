import BridgeCore
import Foundation

struct TestFailure: Error, CustomStringConvertible {
    var description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(description: message)
    }
}

@main
struct BridgeCoreFocusedTests {
    static func main() async throws {
        try testExactCodexCommandsBypassNormalPromptBatching()
        try testCapabilityFormattingAndCacheSnapshot()
        try testThreadHistoryFormattingSummarizesLastThreeTurns()
        try testEmptyHistoryHasClearDegradedMessage()
        try await testAppServerClientThreadReadSuccessAndCleanup()
        try await testAppServerClientRpcErrorAndCleanup()
        try await testAppServerClientInvalidResultAndTimeout()
        try testCodexProgressSummaryHandlesAppServerNotifications()
        try await testOrdinaryTextDuringActiveJobQueuesNextBatchWhileCodexStatusCutsThrough()
        print("BridgeCoreTests passed.")
    }

    private static func testExactCodexCommandsBypassNormalPromptBatching() throws {
        try expect(bridgeLocalCommandName("/codex status") == "/codex", "exact codex status command")
        try expect(bridgeLocalCommandName("  /codex open  ") == "/codex", "exact codex open command")
        try expect(bridgeLocalCommandName("/codex history") == "/codex", "exact codex history command")
        try expect(bridgeLocalCommandName("/codex status please") == nil, "non-exact codex command is prompt text")
        try expect(bridgeLocalCommandName("what does /codex status show?") == nil, "natural language codex mention is prompt text")
        try expect(bridgeLocalCommandName("/status please") == "/status", "existing command arguments still work")
    }

    private static func testCapabilityFormattingAndCacheSnapshot() throws {
        let capabilities = CodexCapabilities(version: "0.130.0", appServerAvailable: true, remoteControlAvailable: true, threadReadAvailable: true, warnings: [])
        try expect(capabilities.enhancedBridgeUXAvailable, "enhanced bridge UX availability")
        try expect(formatCodexCapabilityLines(capabilities).contains("Enhanced bridge UX: yes"), "capability formatter says yes")
        let snapshot = CodexCapabilitySnapshot(capabilities: capabilities, cachedAt: "2026-05-09T00:00:00.000Z", refreshed: false, cacheAgeSeconds: 12)
        try expect(formatCodexCapabilityCacheLine(snapshot) == "Codex capability cache: cached at 2026-05-09T00:00:00.000Z, age 12s", "capability cache formatter")
    }

    private static func testThreadHistoryFormattingSummarizesLastThreeTurns() throws {
        let result: [String: Any] = [
            "thread": [
                "id": "thread-1",
                "turns": [
                    turn(status: "completed", user: "one", answer: "first"),
                    turn(status: "completed", user: "two", answer: "second"),
                    turn(status: "failed", user: "three", answer: "third"),
                    turn(status: "running", user: "four", answer: "fourth")
                ]
            ]
        ]
        let history = codexThreadHistory(from: result, fallbackThreadId: "fallback")
        try expect(history.threadId == "thread-1", "history thread id")
        try expect(history.turns.map(\.userPreview) == ["two", "three", "four"], "history keeps last three turns")
        let text = formatCodexThreadHistory(history)
        try expect(text.contains("codex://threads/thread-1"), "history includes deep link")
        try expect(text.contains("1. completed"), "history includes first displayed status")
        try expect(text.contains("3. running"), "history includes last displayed status")
    }

    private static func testEmptyHistoryHasClearDegradedMessage() throws {
        let history = codexThreadHistory(from: ["thread": ["id": "thread-empty", "turns": []]], fallbackThreadId: "fallback")
        try expect(formatCodexThreadHistory(history) == "Codex thread thread-empty has no loaded turns yet.\nCodex thread link: codex://threads/thread-empty", "empty history message")
    }

    private static func testAppServerClientThreadReadSuccessAndCleanup() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"method":"turn/started","params":{"turnId":"turn-1"}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-1","turns":[{"status":"completed","updatedAt":"2026-05-09T00:00:00.000Z","items":[{"type":"userMessage","content":"hello"},{"type":"agentMessage","phase":"final_answer","text":"hi"}]}]}}}"#
        ])
        let history = try await CodexAppServerClient(timeoutMs: 500) { fake }.threadRead(threadId: "thread-1")
        try expect(history.turns.first?.userPreview == "hello", "app-server user preview")
        try expect(history.turns.first?.answerPreview == "hi", "app-server answer preview")
        try expect(fake.sentMethods == ["initialize", "initialized", "thread/read"], "app-server request sequence")
        try expect(fake.closed, "app-server connection closes after success")
    }

    private static func testAppServerClientRpcErrorAndCleanup() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"error":{"message":"missing thread"}}"#
        ])
        do {
            _ = try await CodexAppServerClient(timeoutMs: 500) { fake }.threadRead(threadId: "missing")
            throw TestFailure(description: "Expected threadRead to throw")
        } catch let error as CodexAppServerError {
            try expect(error == .rpcError("missing thread"), "app-server rpc error")
            try expect(fake.closed, "app-server connection closes after rpc error")
        }
    }

    private static func testAppServerClientInvalidResultAndTimeout() async throws {
        let invalid = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":"not an object"}"#
        ])
        do {
            _ = try await CodexAppServerClient(timeoutMs: 500) { invalid }.threadRead(threadId: "thread")
            throw TestFailure(description: "Expected invalid result")
        } catch let error as CodexAppServerError {
            try expect(error == .invalidResponse("Codex app-server response 2 did not include an object result."), "invalid app-server result")
        }

        let timedOut = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#
        ], diagnostics: "stderr detail")
        do {
            _ = try await CodexAppServerClient(timeoutMs: 100) { timedOut }.threadRead(threadId: "thread")
            throw TestFailure(description: "Expected timeout")
        } catch let error as CodexAppServerError {
            try expect(error == .timedOut("Timed out waiting for Codex app-server response 2: stderr detail"), "app-server timeout")
        }
    }

    private static func testCodexProgressSummaryHandlesAppServerNotifications() throws {
        try expect(codexProgressSummary(from: ["method": "turn/started", "params": ["turnId": "turn-1"]]) == "Codex turn started.", "turn started summary")
        try expect(codexProgressSummary(from: ["method": "item/started", "params": ["item": ["type": "mcp_tool_call", "tool": "computer-use"]]]) == "Started computer-use", "tool started summary")
        let parser = CodexStreamParser()
        let events = parser.consume(#"{"method":"item/completed","params":{"item":{"type":"command_execution","command":"swift test","status":"completed"}}}"# + "\n", stream: .stdout)
        try expect(events == [.progress("Completed swift test (completed)")], "parser emits app-server progress")
    }

    private static func testOrdinaryTextDuringActiveJobQueuesNextBatchWhileCodexStatusCutsThrough() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 10_000
        try stores.config.save(config)
        try writeCapabilityCache(paths: paths)
        try stores.state.save(BridgeState(
            lastProcessedGuid: nil,
            lastProcessedRowId: 0,
            pendingBatch: nil,
            activeJob: ActiveJob(
                jobId: "job-1",
                guid: "active",
                rowId: 1,
                type: "promptBatch",
                receivedAt: "2026-05-09T00:00:00.000Z",
                promptPreview: "active work",
                recipient: "+1",
                service: "iMessage",
                startedAt: "2026-05-09T00:00:00.000Z",
                lastProgressAt: "2026-05-09T00:00:02.000Z",
                lastUserUpdateAt: nil,
                lastEventAt: nil,
                codexPid: ProcessInfo.processInfo.processIdentifier,
                codexSessionId: "thread-active",
                outputPath: nil,
                sessionLogPath: nil,
                status: "running",
                lastObservedSummary: "Running command.",
                permissionRecoveryAttempts: 0,
                waitingForPermissionSince: nil,
                lastPermissionEventId: nil
            ),
            codexSession: CodexSessionState(sessionId: "thread-active", startedAt: nil, lastPromptAt: "2026-05-09T00:00:00.000Z", lastCompletedAt: nil, expiresAt: nil, lastErrorAt: nil)
        ))

        let source = QueueMessageSource(messages: [
            message(rowId: 10, text: "ordinary follow up"),
            message(rowId: 11, text: "/codex status")
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { CodexExecAdapter(config: $0, paths: paths) },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()

        let state = try stores.state.load()
        try expect(state.pendingBatch?.items.map(\.text) == ["ordinary follow up"], "ordinary active-job text queues as next batch")
        let replies = await sink.repliesSnapshot()
        try expect(replies.count == 1, "status command cuts through active job")
        let reply = try expectReply(replies.first)
        try expect(reply.text.contains("Codex bridge status:"), "status reply header")
        try expect(reply.text.contains("Active backend: codex exec"), "status reply backend")
        try expect(reply.text.contains("Latest Codex progress: Running command."), "status reply progress")
    }

    private static func turn(status: String, user: String, answer: String) -> [String: Any] {
        [
            "status": status,
            "updatedAt": "2026-05-09T00:00:00.000Z",
            "items": [
                ["type": "userMessage", "content": user],
                ["type": "agentMessage", "phase": "final_answer", "text": answer]
            ]
        ]
    }

    private static func expectReply(_ reply: CapturingReplySink.Reply?) throws -> CapturingReplySink.Reply {
        guard let reply else {
            throw TestFailure(description: "Expected captured reply")
        }
        return reply
    }
}

private final class FakeCodexAppServerConnection: CodexAppServerConnection, @unchecked Sendable {
    private var lines: [String]
    private let diagnosticsText: String
    private(set) var sentMethods: [String] = []
    private(set) var closed = false

    init(lines: [String], diagnostics: String = "") {
        self.lines = lines
        self.diagnosticsText = diagnostics
    }

    var diagnostics: String { diagnosticsText }

    func start() throws {}

    func send(_ message: [String: Any]) throws {
        sentMethods.append(message["method"] as? String ?? "")
    }

    func readLine(deadline: Date) throws -> String? {
        lines.isEmpty ? nil : lines.removeFirst()
    }

    func close() {
        closed = true
    }
}

private final class QueueMessageSource: MessageSource {
    private var messages: [MessageItem]

    init(messages: [MessageItem]) {
        self.messages = messages
    }

    func initializeCursor(state: inout BridgeState) async throws {}

    func fetchNewMessages(afterRowId: Int64) async throws -> [MessageItem] {
        let result = messages.filter { $0.rowId > afterRowId }
        messages.removeAll()
        return result
    }
}

private final class CapturingReplySink: ReplySink, @unchecked Sendable {
    struct Reply: Equatable {
        var recipient: String
        var service: String
        var text: String
    }

    private let collector = ReplyCollector()

    func repliesSnapshot() async -> [Reply] {
        await collector.snapshot()
    }

    func sendReply(recipient: String, service: String, text: String) async throws {
        await collector.append(Reply(recipient: recipient, service: service, text: text))
    }

    func sendAttachment(recipient: String, service: String, filePath: String) async throws {}
}

private actor ReplyCollector {
    private var replies: [CapturingReplySink.Reply] = []

    func append(_ reply: CapturingReplySink.Reply) {
        replies.append(reply)
    }

    func snapshot() -> [CapturingReplySink.Reply] {
        replies
    }
}

private func testPaths() -> RuntimePaths {
    let root = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("MessagesCodexBridgeTests")
        .appendingPathComponent(UUID().uuidString)
    let appSupport = root.appendingPathComponent("app-support")
    let logs = root.appendingPathComponent("logs")
    let launchAgents = root.appendingPathComponent("launch-agents")
    return RuntimePaths.current(
        projectRoot: root.appendingPathComponent("messages-codex-bridge-mac"),
        environment: [
            "MESSAGES_LLM_BRIDGE_HOME": appSupport.path,
            "MESSAGES_LLM_BRIDGE_LOG_DIR": logs.path,
            "MESSAGES_LLM_BRIDGE_LAUNCH_AGENTS_DIR": launchAgents.path
        ]
    )
}

private func message(rowId: Int64, text: String) -> MessageItem {
    MessageItem(rowId: rowId, guid: "guid-\(rowId)", text: text, handleId: "+1", service: "iMessage", receivedAt: "2026-05-09T00:00:00.000Z", attachments: [])
}

private func writeCapabilityCache(paths: RuntimePaths) throws {
    try FileManager.default.createDirectory(at: paths.stateDir, withIntermediateDirectories: true)
    let data = Data("""
    {
      "cachedAt" : "2026-05-09T00:00:00.000Z",
      "capabilities" : {
        "version" : "0.130.0",
        "appServerAvailable" : true,
        "remoteControlAvailable" : true,
        "threadReadAvailable" : true,
        "warnings" : []
      }
    }
    """.utf8)
    try data.write(to: paths.stateDir.appendingPathComponent("codex-capabilities.json"), options: .atomic)
}
