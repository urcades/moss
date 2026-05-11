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
        try await testAppServerBackendStartsThreadAndReturnsFinalAnswer()
        try await testAppServerBackendNamesNewThreadFromPrompt()
        try await testAppServerBackendResumesThreadAndIgnoresMalformedNotifications()
        try await testAppServerBackendErrorNotificationThrowsBridgeFailure()
        try testCodexProgressSummaryHandlesAppServerNotifications()
        try await testProgressEventsUpdateStateWithoutSendingSms()
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

    private static func testAppServerBackendStartsThreadAndReturnsFinalAnswer() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-new","path":"/tmp/thread.jsonl"}}}"#,
            #"{"method":"thread/started","params":{"thread":{"id":"thread-new","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-new"}}}"#,
            #"{"method":"turn/started","params":{"threadId":"thread-new","turn":{"id":"turn-new"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-new","turnId":"turn-new","item":{"type":"agentMessage","id":"item-note","status":"completed","text":"old note mentioning Apple event error -1743"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-new","turnId":"turn-new","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"hello from app server"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-new","turn":{"id":"turn-new","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }
        let eventCollector = CodexEventCollector()
        let response = try await backend.invoke(PromptRequest(promptText: "hello", attachments: []), sessionId: nil) { event in
            eventCollector.append(event)
        }
        let events = eventCollector.snapshot()
        try expect(response.text == "hello from app server", "app-server backend final answer")
        try expect(response.sessionId == "thread-new", "app-server backend returns thread id")
        try expect(fake.sentMethods == ["initialize", "initialized", "thread/start", "turn/start"], "app-server start request sequence")
        try expect(events.contains(.processStarted(4242)), "app-server process started event")
        try expect(events.contains(.sessionStarted("thread-new")), "app-server session event")
        try expect(events.contains(.turnStarted("turn-new")), "app-server turn event")
        try expect(!events.contains { event in
            if case .blocker = event { return true }
            return false
        }, "completed app-server items do not become permission blockers")
        try expect(fake.closed, "app-server backend closes connection")
    }

    private static func testAppServerBackendNamesNewThreadFromPrompt() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-new","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"ok":true}}"#,
            #"{"id":4,"result":{"turn":{"id":"turn-new"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-new","turnId":"turn-new","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"named"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-new","turn":{"id":"turn-new","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }
        let request = PromptRequest(
            promptText: "These Apple Messages arrived within one short window.\n\nMessage 1:\nCan you make the bridge title threads more clearly?",
            attachments: [],
            threadName: "Can you make the bridge title threads more clearly?"
        )

        _ = try await backend.invoke(request, sessionId: nil, onEvent: nil)

        try expect(fake.sentMethods == ["initialize", "initialized", "thread/start", "thread/name/set", "turn/start"], "new app-server thread is named before turn start")
        let nameRequest = fake.sentMessages.first { $0["method"] as? String == "thread/name/set" }
        let params = nameRequest?["params"] as? [String: Any]
        try expect(params?["threadId"] as? String == "thread-new", "thread name request targets new thread")
        try expect(params?["name"] as? String == "Can you make the bridge title threads more clearly?", "thread name comes from message text")
    }

    private static func testAppServerBackendResumesThreadAndIgnoresMalformedNotifications() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            "not json",
            #"{"id":2,"result":{"thread":{"id":"thread-existing"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-resumed"}}}"#,
            #"{"method":"unknown/event","params":{"ignored":true}}"#,
            #"{"method":"item/agentMessage/delta","params":{"threadId":"thread-existing","turnId":"turn-resumed","itemId":"item-1","delta":"resumed "}}"#,
            #"{"method":"item/agentMessage/delta","params":{"threadId":"thread-existing","turnId":"turn-resumed","itemId":"item-1","delta":"answer"}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-existing","turnId":"turn-resumed","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"resumed answer"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-existing","turn":{"id":"turn-resumed","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }
        let response = try await backend.invoke(PromptRequest(promptText: "resume", attachments: []), sessionId: "thread-existing", onEvent: nil)
        try expect(response.text == "resumed answer", "app-server resume final answer")
        try expect(response.sessionId == "thread-existing", "app-server resume keeps thread id")
        try expect(fake.sentMethods == ["initialize", "initialized", "thread/resume", "turn/start"], "app-server resume request sequence")
    }

    private static func testAppServerBackendErrorNotificationThrowsBridgeFailure() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-error"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-error"}}}"#,
            #"{"method":"error","params":{"threadId":"thread-error","turnId":"turn-error","error":{"message":"boom"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-error","turn":{"id":"turn-error","status":"completed","error":null}}}"#
        ], diagnostics: "stderr details")
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }
        do {
            _ = try await backend.invoke(PromptRequest(promptText: "fail", attachments: []), sessionId: nil, onEvent: nil)
            throw TestFailure(description: "Expected app-server backend failure")
        } catch let error as CodexBackendFailure {
            try expect(error.message.contains("boom"), "app-server error notification text")
            try expect(error.stderr == "stderr details", "app-server error diagnostics")
        }
    }

    private static func testCodexProgressSummaryHandlesAppServerNotifications() throws {
        try expect(codexProgressSummary(from: ["method": "turn/started", "params": ["turnId": "turn-1"]]) == "Codex turn started.", "turn started summary")
        try expect(codexProgressSummary(from: ["method": "item/started", "params": ["item": ["type": "mcp_tool_call", "tool": "computer-use"]]]) == "Started computer-use", "tool started summary")
        let parser = CodexStreamParser()
        let events = parser.consume(#"{"method":"item/completed","params":{"item":{"type":"command_execution","command":"swift test","status":"completed"}}}"# + "\n", stream: .stdout)
        try expect(events == [.progress("Completed swift test (completed)")], "parser emits app-server progress")
    }

    private static func testProgressEventsUpdateStateWithoutSendingSms() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-1", text: "run a harmless probe", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in
                FakeProgressCodexBackend(
                    events: [
                        .sessionStarted("thread-progress"),
                        .turnStarted("turn-progress"),
                        .progress("LEAKY INTERNAL PROGRESS"),
                        .milestone("LEAKY INTERNAL MILESTONE")
                    ],
                    response: "final answer only"
                )
            },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()
        for _ in 0..<40 {
            if await sink.repliesSnapshot().count >= 1 { break }
            try await Task.sleep(nanoseconds: 25_000_000)
        }

        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text) == ["final answer only"], "progress and milestone events are state-only, not SMS replies")
        let state = try stores.state.load()
        try expect(state.codexSession.sessionId == "thread-progress", "progress test keeps app-server thread id")
        try expect(state.activeJob == nil, "progress test clears completed active job")
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
        try expect(reply.text.contains("Active backend: codex app-server"), "status reply backend")
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
    private(set) var sentMessages: [[String: Any]] = []
    private(set) var closed = false

    init(lines: [String], diagnostics: String = "") {
        self.lines = lines
        self.diagnosticsText = diagnostics
    }

    var diagnostics: String { diagnosticsText }
    var processIdentifier: Int32? { 4242 }

    func start() throws {}

    func send(_ message: [String: Any]) throws {
        sentMethods.append(message["method"] as? String ?? "")
        sentMessages.append(message)
    }

    func readLine(deadline: Date) throws -> String? {
        lines.isEmpty ? nil : lines.removeFirst()
    }

    func close() {
        closed = true
    }
}

private final class CodexEventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [CodexStreamEvent] = []

    func append(_ event: CodexStreamEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    func snapshot() -> [CodexStreamEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }
}

private final class FakeProgressCodexBackend: CodexBackend {
    let events: [CodexStreamEvent]
    let response: String

    init(events: [CodexStreamEvent], response: String) {
        self.events = events
        self.response = response
    }

    func invoke(_ request: PromptRequest, sessionId: String?, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse {
        for event in events {
            onEvent?(event)
        }
        return CodexResponse(
            text: response,
            sessionId: "thread-progress",
            stdout: "",
            stderr: "",
            args: [],
            outputPath: ""
        )
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
        projectRoot: root,
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
