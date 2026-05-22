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
        try testBridgeInstructionsRouteAutomationAndPluginRequests()
        try testAutomationRequestsGetRoutingGuard()
        try testPromptBatchPreservesPluginIntentAndOrder()
        try await testRecentMissingAttachmentDefersCursorUntilFileExists()
        try await testSQLiteMessageSourceAttachmentRowsAndClassification()
        try testPreviousImageReferenceAddsRecentImage()
        try await testMissingPreviousImageReferenceAsksForSource()
        try await testCodexSmokeAttachmentCommandSendsProbeAndSummary()
        try await testCodexSmokeCapabilityCommandRunsAppServerProbe()
        try await testCodexSmokeCallbackCapturesNextReplyAndClearsState()
        try testInboundImageSmokeBuildsLocalImageRequest()
        try testInboundImageSmokeRequiresTrustedInboundImage()
        try await testInboundImageSmokeRecoversLatestTrustedImageFromMessagesDb()
        try testDiagnosticMentionOfDailyBriefingDoesNotCreateAutomation()
        try testAutomationCreationClassifierMatrix()
        try testCodexAutomationCreationWritesAppAutomationToml()
        try testCodexAutomationSmokeCreatesRouteAndStatus()
        try testBridgeStateSavePreservesConcurrentAutomationFields()
        try testCapabilityFormattingAndCacheSnapshot()
        try await testCapabilityBestEffortPrefersCache()
        try await testOutboundSmokeTextEvidenceFindsMarkerInMessagesDb()
        try await testOutboundSmokeAttachmentEvidenceFindsMarkerInTransferName()
        try await testOutboundSmokeAttachmentEvidenceFallsBackToLatestAttachment()
        try await testClipboardAttachmentSendRetriesWhenNoDbRowAppears()
        try await testRecentFailedOutboundEvidenceFindsFailedTextAndAttachmentRows()
        try testCodexAppServerProcessSnapshotParsesTransportsAndOrphans()
        try testCodexMentionExtraction()
        try testNaturalLanguageCodexMentionExtraction()
        try await testAppServerClientCapabilityInventory()
        try testThreadHistoryFormattingSummarizesLastThreeTurns()
        try testEmptyHistoryHasClearDegradedMessage()
        try testAutomationDirectiveStripping()
        try testSmsUrlRecipientNormalizesPhoneNumbers()
        try await testAppServerClientThreadReadSuccessAndCleanup()
        try await testAppServerClientRpcErrorAndCleanup()
        try await testAppServerClientInvalidResultAndTimeout()
        try await testAppServerTimeoutTerminatesChildProcesses()
        try await testAppServerBackendStartsThreadAndReturnsFinalAnswer()
        try await testAppServerBackendAddsCapabilityInventoryToDeveloperInstructions()
        try await testAppServerBackendAddsStructuredMentionsToTurnInput()
        try await testAppServerBackendUsesReadOnlySandboxForAutomationRequests()
        try await testAppServerBackendRejectsNonFinalAgentMessageAsReply()
        try await testAppServerBackendForwardsDynamicToolRequests()
        try await testAppServerBackendRejectsUnsupportedDynamicToolNamespace()
        try await testAppServerBackendHandlesMalformedDynamicToolRequest()
        try await testAppServerBackendNormalizesOddDynamicToolResponses()
        try await testAppServerBackendResolvesInteractiveCallbacksWithResponder()
        try await testAppServerBackendBlocksUserInputAndElicitationRequests()
        try await testBridgeDefaultBackendInteractiveCallbackEndToEnd()
        try await testAppServerBackendNamesNewThreadFromPrompt()
        try await testAppServerBackendResumesThreadAndIgnoresMalformedNotifications()
        try await testAppServerBackendErrorNotificationThrowsBridgeFailure()
        try testCodexProgressSummaryHandlesAppServerNotifications()
        try testOutgoingAttachmentIntentGate()
        try await testBridgeAttachDirectiveAlwaysSendsValidatedAttachment()
        try await testProgressEventsUpdateStateWithoutSendingSms()
        try await testDeadActiveJobOnStartupNotifiesAndClears()
        try await testPendingInteractiveCallbackCapturesNextReply()
        try await testPendingInteractiveCallbackCancelAndTimeout()
        try testCorruptedStateJsonBacksUpAndDefaults()
        try testStateRecoveryBackupDiagnosticsReportBackupPath()
        try testLaunchAgentProgramDiagnostics()
        try await testAutomationRequestCreatesCodexAutomationFromInterpretedSpec()
        try await testCodexAutomationsReportsCreationInProgress()
        try await testCompletedAutomationSessionIsForwardedOnce()
        try testCompletedAutomationScanUsesDeliveredSessionLowerBound()
        try testTerminateProcessTreeIncludesRoot()
        try await testOrdinaryTextDuringActiveJobQueuesNextBatchWhileCodexStatusCutsThrough()
        print("BridgeCoreTests passed.")
    }

    private static func testExactCodexCommandsBypassNormalPromptBatching() throws {
        try expect(bridgeLocalCommandName("/codex status") == "/codex", "exact codex status command")
        try expect(bridgeLocalCommandName("  /codex open  ") == "/codex", "exact codex open command")
        try expect(bridgeLocalCommandName("/codex history") == "/codex", "exact codex history command")
        try expect(bridgeLocalCommandName("/codex automations") == "/codex", "exact codex automations command")
        try expect(bridgeLocalCommandName("/codex retry-last-send") == "/codex", "exact codex retry command")
        try expect(bridgeLocalCommandName("/codex smoke text") == "/codex", "codex text smoke command")
        try expect(bridgeLocalCommandName("/codex smoke attachment") == "/codex", "codex attachment smoke command")
        try expect(bridgeLocalCommandName("/codex smoke browser") == "/codex", "codex browser smoke command")
        try expect(bridgeLocalCommandName("/codex smoke chrome") == "/codex", "codex chrome smoke command")
        try expect(bridgeLocalCommandName("/codex smoke computer-use") == "/codex", "codex computer-use smoke command")
        try expect(bridgeLocalCommandName("/codex smoke automation") == "/codex", "codex automation smoke command")
        try expect(bridgeLocalCommandName("/codex smoke callback") == "/codex", "codex callback smoke command")
        try expect(bridgeLocalCommandName("/codex smoke inbound-image-check") == "/codex", "codex inbound image smoke command")
        try expect(bridgeLocalCommandName("/codex smoke unknown") == nil, "unsupported codex smoke command is prompt text")
        try expect(bridgeLocalCommandName("/codex status please") == nil, "non-exact codex command is prompt text")
        try expect(bridgeLocalCommandName("what does /codex status show?") == nil, "natural language codex mention is prompt text")
        try expect(bridgeLocalCommandName("/status please") == "/status", "existing command arguments still work")
    }

    private static func testBridgeInstructionsRouteAutomationAndPluginRequests() throws {
        let instructions = BridgeConstants.baseBridgeInstructions
        try expect(instructions.contains("remote control surface for Codex running on this Mac"), "bridge instructions describe Messages as Codex remote control")
        try expect(instructions.contains("use Codex automation tools"), "bridge instructions route automation requests to Codex tools")
        try expect(instructions.contains("do not implement a replacement inside the Messages bridge"), "bridge instructions prevent bridge scheduler invention")
        try expect(instructions.contains("name plugins, skills, apps, or tools"), "bridge instructions route plugin and skill requests")
        try expect(instructions.contains("Do not modify the Messages bridge itself unless the user explicitly asks"), "bridge instructions prevent accidental bridge edits")
    }

    private static func testAutomationRequestsGetRoutingGuard() throws {
        let guardedBatch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-12T00:00:00.000Z",
            deadlineAt: "2026-05-12T00:00:01.000Z",
            items: [
                MessageItem(rowId: 1, guid: "guarded", text: "Create an automation that sends me a daily digest every morning.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-12T00:00:00.000Z", attachments: [])
            ]
        )
        let guarded = buildPromptRequest(from: guardedBatch)
        try expect(guarded.promptText.contains("Bridge routing guard:"), "automation prompt gets bridge routing guard")
        try expect(guarded.promptText.contains("Do not implement, modify, inspect, or continue any Messages bridge scheduler"), "automation guard blocks bridge scheduler work")
        try expect(guarded.promptText.contains("If a Codex automation tool is available, use it"), "automation guard routes to Codex automation tools")

        let bridgeSourceBatch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-12T00:00:00.000Z",
            deadlineAt: "2026-05-12T00:00:01.000Z",
            items: [
                MessageItem(rowId: 2, guid: "source", text: "Please modify the Messages bridge source code for its automation handling.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-12T00:00:00.000Z", attachments: [])
            ]
        )
        let explicitBridgeWork = buildPromptRequest(from: bridgeSourceBatch)
        try expect(!explicitBridgeWork.promptText.contains("Bridge routing guard:"), "explicit bridge source work is not sandboxed as an automation request")
    }

    private static func testPromptBatchPreservesPluginIntentAndOrder() throws {
        let attachmentPath = NSTemporaryDirectory() + "/bridge-prompt-batch-image.png"
        FileManager.default.createFile(atPath: attachmentPath, contents: Data(), attributes: nil)
        let batch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-20T10:00:00.000Z",
            deadlineAt: "2026-05-20T10:00:01.000Z",
            items: [
                MessageItem(rowId: 10, guid: "first", text: "First, use @Chrome to inspect the page.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-20T10:00:00.000Z", attachments: []),
                MessageItem(rowId: 11, guid: "second", text: "Then summarize this image.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-20T10:00:01.000Z", attachments: [
                    AttachmentRef(attachmentId: 99, transferName: "page.png", mimeType: "image/png", uti: nil, absolutePath: attachmentPath, kind: "image", exists: false)
                ])
            ]
        )

        let request = buildPromptRequest(from: batch)
        try expect(request.promptText.contains("These Apple Messages arrived within one short window"), "batch preamble is preserved")
        try expect(request.promptText.contains("Message 1:\nFirst, use @Chrome to inspect the page.\n\nMessage 2:\nThen summarize this image."), "message order is preserved")
        try expect(request.promptText.contains("page.png (image/png) at \(attachmentPath)"), "attachment path is preserved")
        try expect(request.attachments.first?.absolutePath == attachmentPath, "image attachment is passed through")
        try expect(extractCodexMentionRefs(from: request.promptText).contains(CodexMentionRef(name: "Chrome", path: "plugin://chrome@openai-bundled")), "batch preamble does not hide Chrome intent")
    }

    private static func testRecentMissingAttachmentDefersCursorUntilFileExists() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let attachmentPath = paths.tmpDir.appendingPathComponent("delayed-image.png")
        let receivedAt = Date(timeIntervalSince1970: 99)
        let message = MessageItem(
            rowId: 1,
            guid: "guid-delayed-attachment",
            text: "Please describe this image.",
            handleId: "+1",
            service: "iMessage",
            receivedAt: DateCodec.iso(receivedAt),
            attachments: [
                AttachmentRef(
                    attachmentId: 44,
                    transferName: "delayed-image.png",
                    mimeType: "image/png",
                    uti: nil,
                    absolutePath: attachmentPath.path,
                    kind: "image",
                    exists: false
                )
            ]
        )
        let source = PersistentMessageSource(messages: [message])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "processed delayed attachment")
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in backend },
            now: { Date(timeIntervalSince1970: 100) }
        )

        try await service.initialize()
        try await service.tick()
        var state = try stores.state.load()
        var replies = await sink.repliesSnapshot()
        try expect(state.lastProcessedRowId == 0, "recent missing attachment does not advance cursor")
        try expect(state.pendingBatch == nil, "recent missing attachment does not enter prompt batch")
        try expect(replies.isEmpty, "recent missing attachment does not start Codex")
        var staleMessage = message
        staleMessage.receivedAt = DateCodec.iso(Date(timeIntervalSince1970: 60))
        try expect(!shouldDeferMessageForMissingAttachments(staleMessage, now: Date(timeIntervalSince1970: 100)), "stale missing attachment does not defer forever")

        try Data("image".utf8).write(to: attachmentPath)
        try await service.tick()
        replies = try await waitForReplies(sink, count: 1)
        state = try await waitForState(stores, timeout: 3) { $0.lastProcessedRowId == 1 && $0.activeJob == nil }
        let request = await backend.requestSnapshot()

        try expect(state.lastProcessedRowId == 1, "ready delayed attachment advances cursor")
        try expect(replies.contains { $0.text.contains("processed delayed attachment") }, "ready delayed attachment starts Codex")
        try expect(request?.attachments.first?.absolutePath == attachmentPath.path, "ready delayed attachment reaches Codex request")
        try expect(request?.attachments.first?.exists == true, "ready delayed attachment is refreshed as existing")
    }

    private static func testSQLiteMessageSourceAttachmentRowsAndClassification() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        let home = paths.tmpDir.appendingPathComponent("home")
        let pictures = home.appendingPathComponent("Pictures")
        try FileManager.default.createDirectory(at: pictures, withIntermediateDirectories: true)
        let image = pictures.appendingPathComponent("photo.png")
        let pdf = paths.tmpDir.appendingPathComponent("paper.pdf")
        let unsupported = paths.tmpDir.appendingPathComponent("archive.weird")
        try Data("image".utf8).write(to: image)
        try Data("%PDF".utf8).write(to: pdf)

        try runSQLite(db, """
        INSERT INTO handle (ROWID, id, service)
        VALUES (1, '+15551234567', 'iMessage');
        INSERT INTO message (ROWID, guid, text, is_from_me, date, service, handle_id)
        VALUES (10, 'attachment-only', '', 0, 0, 'iMessage', 1);
        INSERT INTO attachment (ROWID, transfer_name, filename, mime_type, uti, transfer_state)
        VALUES (100, 'photo.png', '~/Pictures/photo.png', 'image/png', 'public.png', 5);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (10, 100);
        INSERT INTO message (ROWID, guid, text, is_from_me, date, service, handle_id)
        VALUES (11, 'multi-attachment', 'Here are files', 0, 0, 'iMessage', 1);
        INSERT INTO attachment (ROWID, transfer_name, filename, mime_type, uti, transfer_state)
        VALUES
          (101, 'paper.pdf', \(sqliteStringLiteral(pdf.path)), 'application/pdf', 'com.adobe.pdf', 5),
          (102, 'archive.weird', \(sqliteStringLiteral(unsupported.path)), 'application/octet-stream', 'public.data', 5);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (11, 101), (11, 102);
        """)
        let source = SQLiteMessageSource(
            dbPath: db.path,
            trustedSenders: ["+15551234567"],
            homeDir: home.path
        )

        let latest = try await source.latestMatchingMessage()
        let messages = try await source.fetchNewMessages(afterRowId: 0)

        try expect(latest?.rowId == 11, "sqlite source latest attachment row")
        try expect(messages.map(\.rowId) == [10, 11], "sqlite source returns attachment-only and multi-attachment rows")
        try expect(messages[0].text.isEmpty, "sqlite source preserves attachment-only empty text")
        try expect(messages[0].attachments.count == 1, "sqlite source returns attachment-only attachment")
        try expect(messages[0].attachments[0].absolutePath == image.path, "sqlite source expands tilde attachment path")
        try expect(messages[0].attachments[0].kind == "image", "sqlite source classifies image attachment")
        try expect(messages[0].attachments[0].exists, "sqlite source records existing image attachment")
        try expect(messages[1].attachments.map(\.kind) == ["pdf", "unsupported"], "sqlite source classifies pdf and unsupported attachments")
        try expect(messages[1].attachments.map(\.exists) == [true, false], "sqlite source records attachment existence")
    }

    private static func testPreviousImageReferenceAddsRecentImage() throws {
        let imagePath = NSTemporaryDirectory() + "/bridge-recent-source.png"
        FileManager.default.createFile(atPath: imagePath, contents: Data("image".utf8), attributes: nil)
        let batch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-20T10:00:00.000Z",
            deadlineAt: "2026-05-20T10:00:01.000Z",
            items: [
                MessageItem(rowId: 12, guid: "follow-up", text: "Modify that image to make the background blue.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-20T10:00:00.000Z", attachments: [])
            ]
        )
        let recent = RecentMediaRef(direction: "inbound", rowId: 11, handleId: "+1", service: "iMessage", path: imagePath, transferName: "source.png", kind: "image", createdAt: "2026-05-20T09:59:00.000Z", exists: true)

        let request = buildPromptRequest(from: batch, recentMediaRefs: [recent])

        try expect(request.attachments.map(\.absolutePath) == [imagePath], "previous image reference attaches recent image")
        try expect(request.promptText.contains("Bridge media context:"), "previous image context is explicit")
    }

    private static func testMissingPreviousImageReferenceAsksForSource() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-image-followup", text: "Can you modify that image to add a hat?", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()
        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text) == ["Please send the image you want me to modify, then tell me the edit you want."], "missing image follow-up asks for source")
    }

    private static func testCodexSmokeAttachmentCommandSendsProbeAndSummary() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-attachment", text: "/codex smoke attachment", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()
        let attachments = await sink.attachmentsSnapshot()
        let replies = await sink.repliesSnapshot()

        try expect(attachments.count == 1, "codex smoke attachment sends one image probe")
        try expect(attachments.first?.filePath.hasSuffix(".png") == true, "codex smoke attachment creates png probe")
        try expect(replies.count == 1, "codex smoke attachment sends one summary reply")
        try expect(replies.first?.text.contains("Smoke attachment passed: CODEX_BRIDGE_SMOKE_ATTACHMENT_") == true, "codex smoke attachment reports marker")
        try expect(replies.first?.text.contains("Evidence: attachment dbObserved") == true, "codex smoke attachment reports delivery evidence")
        let state = try stores.state.load()
        try expect(state.lastOutboundSend?.kind == "attachment", "codex smoke attachment preserves probe as last outbound send")
    }

    private static func testCodexSmokeCapabilityCommandRunsAppServerProbe() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-chrome", text: "/codex smoke chrome", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "placeholder")
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in backend },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()
        let replies = await sink.repliesSnapshot()
        let request = await backend.requestSnapshot()

        try expect(replies.count == 1, "codex smoke capability sends one summary reply")
        try expect(replies.first?.text.contains("Smoke chrome passed: CODEX_BRIDGE_SMOKE_CHROME_") == true, "codex smoke capability reports marker")
        try expect(replies.first?.text.contains("Thread id: thread-smoke") == true, "codex smoke capability reports thread id")
        try expect(request?.promptText.contains("Use @Chrome") == true, "codex smoke capability prompts app-server for Chrome")
    }

    private static func testCodexSmokeCallbackCapturesNextReplyAndClearsState() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-callback", text: "/codex smoke callback", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()
        var replies = await sink.repliesSnapshot()
        var state = try stores.state.load()
        try expect(replies.count == 1, "codex smoke callback sends pending instructions")
        try expect(replies.first?.text.contains("Smoke callback pending: CODEX_BRIDGE_SMOKE_CALLBACK_") == true, "codex smoke callback reports pending marker")
        try expect(state.pendingInteractiveCallback?.method == "bridge/smoke/interactiveCallback", "codex smoke callback persists pending callback")

        source.append(MessageItem(rowId: 2, guid: "guid-smoke-callback-answer", text: "callback answer", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:01.000Z", attachments: []))
        try await service.tick()
        replies = await sink.repliesSnapshot()
        state = try stores.state.load()

        try expect(replies.count == 2, "codex smoke callback sends completion reply")
        try expect(replies.last?.text.contains("Smoke callback passed: CODEX_BRIDGE_SMOKE_CALLBACK_") == true, "codex smoke callback reports success marker")
        try expect(replies.last?.text.contains("Captured: callback answer") == true, "codex smoke callback reports captured reply")
        try expect(state.pendingInteractiveCallback == nil, "codex smoke callback clears pending state")
        try expect(state.activeJob == nil, "codex smoke callback does not start a codex job")
    }

    private static func testInboundImageSmokeBuildsLocalImageRequest() throws {
        let imagePath = NSTemporaryDirectory() + "/bridge-inbound-smoke-source.png"
        FileManager.default.createFile(atPath: imagePath, contents: Data("image".utf8), attributes: nil)
        let olderOutbound = RecentMediaRef(direction: "outbound", rowId: 20, handleId: "+1", service: "iMessage", path: imagePath, transferName: "outbound.png", kind: "image", createdAt: "2026-05-20T09:00:00.000Z", exists: true)
        let inbound = RecentMediaRef(direction: "inbound", rowId: 21, handleId: "+1", service: "iMessage", path: imagePath, transferName: "source.png", kind: "image", createdAt: "2026-05-20T10:00:00.000Z", exists: true)

        let smoke = try buildInboundImageSmokeRequest(
            recipient: "+1",
            service: "iMessage",
            recentMediaRefs: [olderOutbound, inbound],
            now: Date(timeIntervalSince1970: 1_778_640_000),
            marker: "CODEXMSGCTL_SMOKE_INBOUND_IMAGE_TEST"
        )

        try expect(smoke.mediaRef == inbound, "inbound image smoke chooses recent trusted inbound image")
        try expect(smoke.request.attachments.count == 1, "inbound image smoke attaches exactly one image")
        try expect(smoke.request.attachments.first?.absolutePath == imagePath, "inbound image smoke passes local image path")
        try expect(smoke.request.promptText.contains("Bridge media context:"), "inbound image smoke uses previous-image bridge context")
    }

    private static func testInboundImageSmokeRequiresTrustedInboundImage() throws {
        let unsupportedPath = NSTemporaryDirectory() + "/bridge-inbound-smoke-source.heic"
        FileManager.default.createFile(atPath: unsupportedPath, contents: Data("image".utf8), attributes: nil)
        do {
            _ = try buildInboundImageSmokeRequest(
                recipient: "+1",
                service: "iMessage",
                recentMediaRefs: [
                    RecentMediaRef(direction: "outbound", rowId: 20, handleId: "+1", service: "iMessage", path: "/tmp/missing.png", transferName: "missing.png", kind: "image", createdAt: "2026-05-20T09:00:00.000Z", exists: true),
                    RecentMediaRef(direction: "inbound", rowId: 21, handleId: "+1", service: "iMessage", path: unsupportedPath, transferName: "source.heic", kind: "image", createdAt: "2026-05-20T09:01:00.000Z", exists: true)
                ],
                marker: "CODEXMSGCTL_SMOKE_INBOUND_IMAGE_TEST"
            )
            throw TestFailure(description: "Expected inbound image smoke precondition failure")
        } catch StoreError.validation(let message) {
            try expect(message.contains("no usable app-server-compatible recent inbound image"), "inbound image smoke explains missing compatible inbound image")
        }
    }

    private static func testInboundImageSmokeRecoversLatestTrustedImageFromMessagesDb() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        let imagePath = paths.tmpDir.appendingPathComponent("inbound-db-image.png")
        try Data("image".utf8).write(to: imagePath)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        try runSQLite(db, """
        INSERT INTO handle (ROWID, id, service)
        VALUES (1, '+15206099095', 'iMessage');
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, service, handle_id)
        VALUES (60, 'inbound-image-guid', '', 0, 0, 0, 'iMessage', 1);
        INSERT INTO attachment (ROWID, transfer_name, filename, mime_type, uti, transfer_state)
        VALUES (15, 'inbound-db-image.png', '\(imagePath.path.replacingOccurrences(of: "'", with: "''"))', 'image/png', 'public.png', 5);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (60, 15);
        """)

        let ref = try await latestTrustedInboundImageMediaRef(config: config, recipient: "+1-520-609-9095", service: "iMessage")

        try expect(ref?.rowId == 60, "inbound image DB recovery finds latest trusted image row")
        try expect(ref?.handleId == "+1-520-609-9095", "inbound image DB recovery stores requested recipient identity")
        try expect(ref?.path == imagePath.path, "inbound image DB recovery expands local path")
        let smoke = try buildInboundImageSmokeRequest(recipient: "+1-520-609-9095", service: "iMessage", recentMediaRefs: [ref!])
        try expect(smoke.request.attachments.first?.absolutePath == imagePath.path, "recovered inbound image feeds smoke request")
    }

    private static func testDiagnosticMentionOfDailyBriefingDoesNotCreateAutomation() throws {
        let text = "I'm confused why sometimes computer use works and sometimes it doesn't, also in your last daily morning briefing X wasn't able to be granted, even though we've granted it before - can you look into this?"
        try expect(!promptLooksLikeCodexAutomationRequest(text), "daily briefing diagnostics are not automation requests")
        try expect(!shouldCreateCodexAutomation(from: text), "daily briefing diagnostics do not create automations")
    }

    private static func testAutomationCreationClassifierMatrix() throws {
        let positives = [
            "Create a new automation every morning at 7am that sends a local news and weather digest.",
            "Set up a reminder to ping me tomorrow at 9am.",
            "Schedule a recurring task that checks the bridge status every Friday.",
            "Remind me next week to review the Messages bridge hardening matrix.",
            "Monitor the Codex changelog daily and tell me if app-server changes ship.",
            "Watch this repo weekly and send me a summary.",
            "Check back in two hours and ask me whether the smoke tests passed.",
            "Follow up with me tomorrow morning about this rollout."
        ]
        for text in positives {
            try expect(promptLooksLikeCodexAutomationRequest(text), "automation classifier should route creation-like prompt: \(text)")
            try expect(shouldCreateCodexAutomation(from: text), "automation classifier should create for: \(text)")
        }

        let negatives = [
            "Can you check whether the Morning News automation is running?",
            "Show me my automations and their routes.",
            "List automations that are bridged to Messages.",
            "Why did the automation fail last night?",
            "Please inspect automation.toml for route mismatch issues.",
            "Can you use the browser to check the WWDC schedule?",
            "What is on my schedule today?",
            "Debug the automation delivery evidence without creating anything.",
            "Remove automation Bridge Smoke Test 123."
        ]
        for text in negatives {
            try expect(!shouldCreateCodexAutomation(from: text), "automation classifier should not create for: \(text)")
        }
    }

    private static func testCodexAutomationCreationWritesAppAutomationToml() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.codex.model = "gpt-test"
        config.codex.reasoningEffort = "low"
        let batch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-12T00:00:00.000Z",
            deadlineAt: "2026-05-12T00:00:01.000Z",
            items: [
                MessageItem(rowId: 3, guid: "automation", text: "Can we create a new automation? Every morning at 7am, send a small morning digest with notable local news and weather.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-12T00:00:00.000Z", attachments: [])
            ]
        )

        let created = try createCodexAutomationIfRequested(
            batch: batch,
            config: config,
            paths: paths,
            now: Date(timeIntervalSince1970: 1_778_640_000),
            spec: CodexAutomationSpec(
                name: "Morning News and Weather Digest",
                prompt: "Create a concise morning digest with notable local news and weather.",
                rrule: "FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0",
                model: "gpt-5.2",
                reasoningEffort: "medium",
                executionEnvironment: "local",
                cwds: ["/Users/moss/Developer/Codex Misc"]
            )
        )

        try expect(created?.id == "morning-news-and-weather-digest", "morning digest automation id")
        try expect(created?.rrule == "FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0", "morning digest automation schedule")
        let tomlPath = try expectPath(created?.path)
        let toml = try String(contentsOfFile: tomlPath, encoding: .utf8)
        try expect(toml.contains(#"kind = "cron""#), "automation toml kind")
        try expect(toml.contains(#"name = "Morning News and Weather Digest""#), "automation toml name")
        try expect(toml.contains(#"status = "ACTIVE""#), "automation toml active")
        try expect(toml.contains(#"model = "gpt-5.2""#), "automation toml model")
        try expect(toml.contains(#"execution_environment = "local""#), "automation toml local execution")
        try expect(toml.contains(#"cwds = ["/Users/moss/Developer/Codex Misc"]"#), "automation toml cwd comes from interpreted spec")
        try expect(!toml.contains("Can we create a new automation?"), "interpreted automation prompt does not duplicate raw request")
    }

    private static func testCodexAutomationSmokeCreatesRouteAndStatus() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.codex.model = "gpt-test"
        config.codex.reasoningEffort = "low"
        try stores.config.save(config)

        let result = try createCodexAutomationSmoke(
            recipient: "+1",
            service: "iMessage",
            config: config,
            paths: paths,
            stores: stores,
            now: Date(timeIntervalSince1970: 1_778_640_000),
            marker: "CODEXMSGCTL_SMOKE_AUTOMATION_TEST"
        )

        try expect(result.marker == "CODEXMSGCTL_SMOKE_AUTOMATION_TEST", "automation smoke marker is preserved")
        try expect(result.automation.name == "Bridge Smoke Test ION_TEST", "automation smoke name uses marker suffix")
        let toml = try String(contentsOfFile: result.automation.path, encoding: .utf8)
        try expect(toml.contains("CODEXMSGCTL_SMOKE_AUTOMATION_TEST"), "automation smoke prompt contains marker")
        try expect(toml.contains(#"rrule = "FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=31;BYHOUR=23;BYMINUTE=59;BYSECOND=0""#), "automation smoke uses harmless far-future schedule")
        let state = try stores.state.load()
        try expect(state.automationRoutes?.contains(where: { $0.automationId == result.automation.id && $0.recipient == "+1" }) == true, "automation smoke route persisted")
        try expect(state.automationCreationStatus?.automationId == result.automation.id, "automation smoke creation status automation id")
        try expect(state.automationCreationStatus?.phase == "confirmed", "automation smoke creation status confirmed")
    }

    private static func testBridgeStateSavePreservesConcurrentAutomationFields() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var existing = defaultBridgeState()
        existing.automationRoutes = [
            CodexAutomationRoute(
                automationId: "bridge-smoke-test",
                name: "Bridge Smoke Test",
                recipient: "+1",
                service: "iMessage",
                createdFromGuid: "guid-1",
                createdFromRowId: 42,
                createdAt: "2026-05-22T07:00:00.000Z"
            )
        ]
        existing.automationCreationStatus = AutomationCreationStatus(
            automationId: "bridge-smoke-test",
            name: "Bridge Smoke Test",
            phase: "confirmed",
            createdFilePath: "/tmp/automation.toml",
            routeStatus: "route persisted",
            confirmationSendStatus: "verified",
            updatedAt: "2026-05-22T07:00:00.000Z"
        )
        existing.recentMediaRefs = [
            RecentMediaRef(
                direction: "inbound",
                rowId: 43,
                handleId: "+1",
                service: "iMessage",
                path: "/tmp/source.png",
                transferName: "source.png",
                kind: "image",
                createdAt: "2026-05-22T07:01:00.000Z",
                exists: true
            )
        ]
        existing.pendingInteractiveCallback = PendingInteractiveCallback(
            callbackId: "callback-1",
            jobId: "job-1",
            jsonRpcId: "70",
            method: "item/tool/requestUserInput",
            recipient: "+1",
            service: "iMessage",
            prompt: "Choose one",
            createdAt: "2026-05-22T07:02:00.000Z",
            expiresAt: "2026-05-22T07:07:00.000Z",
            status: "pending"
        )
        try stores.state.save(existing)

        var staleTickState = defaultBridgeState()
        staleTickState.lastProcessedRowId = 99
        staleTickState.lastProcessedGuid = "newer-message-guid"
        try stores.state.save(staleTickState)

        let reloaded = try stores.state.load()
        try expect(reloaded.lastProcessedRowId == 99, "state save keeps incoming cursor fields")
        try expect(reloaded.automationRoutes?.contains(where: { $0.automationId == "bridge-smoke-test" && $0.createdFromRowId == 42 }) == true, "state save preserves concurrent automation route")
        try expect(reloaded.automationCreationStatus?.automationId == "bridge-smoke-test", "state save preserves concurrent automation creation status")
        try expect(reloaded.recentMediaRefs?.contains(where: { $0.rowId == 43 && $0.path == "/tmp/source.png" }) == true, "state save preserves concurrent recent media refs")
        try expect(recentMediaRefsStatusText(reloaded.recentMediaRefs ?? []).contains("source.png"), "recent media status exposes latest image ref")
        try expect(reloaded.pendingInteractiveCallback?.callbackId == "callback-1", "state save preserves non-terminal pending interactive callback")

        if var completed = reloaded.pendingInteractiveCallback {
            var terminalState = reloaded
            completed.status = "completed"
            terminalState.pendingInteractiveCallback = completed
            try stores.state.save(terminalState)
        }
        var clearState = try stores.state.load()
        clearState.pendingInteractiveCallback = nil
        try stores.state.save(clearState)
        let cleared = try stores.state.load()
        try expect(cleared.pendingInteractiveCallback == nil, "terminal pending interactive callback can be cleared")
    }

    private static func testCapabilityFormattingAndCacheSnapshot() throws {
        let inventory = CodexToolInventory(
            skills: [
                CodexSkillInventoryItem(name: "chrome:Chrome", enabled: true),
                CodexSkillInventoryItem(name: "disabled", enabled: false)
            ],
            plugins: [CodexPluginInventoryItem(name: "openai-bundled", displayName: "OpenAI Bundled")],
            apps: [
                CodexAppInventoryItem(id: "app-1", name: "Notion", isAccessible: true, isEnabled: true),
                CodexAppInventoryItem(id: "app-2", name: "Unavailable", isAccessible: false, isEnabled: true)
            ],
            mcpServers: [CodexMcpServerInventoryItem(name: "node_repl", toolCount: 1)]
        )
        let capabilities = CodexCapabilities(version: "0.130.0", appServerAvailable: true, remoteControlAvailable: true, threadReadAvailable: true, inventory: inventory, warnings: [])
        try expect(capabilities.enhancedBridgeUXAvailable, "enhanced bridge UX availability")
        let formatted = formatCodexCapabilityLines(capabilities).joined(separator: "\n")
        try expect(formatted.contains("Enhanced bridge UX: yes"), "capability formatter says yes")
        try expect(formatted.contains("Codex skills: 1 enabled / 2 total"), "capability formatter includes skill inventory")
        try expect(formatted.contains("Codex apps/connectors: 1 accessible / 2 total"), "capability formatter includes app inventory")
        try expect(formatted.contains("Codex invocation status: Chrome: callable"), "capability formatter separates invocation status")
        let snapshot = CodexCapabilitySnapshot(capabilities: capabilities, cachedAt: "2026-05-09T00:00:00.000Z", refreshed: false, cacheAgeSeconds: 12)
        try expect(formatCodexCapabilityCacheLine(snapshot) == "Codex capability cache: cached at 2026-05-09T00:00:00.000Z, age 12s", "capability cache formatter")
    }

    private static func testCapabilityBestEffortPrefersCache() async throws {
        let paths = testPaths()
        try writeCapabilityCache(paths: paths)

        let snapshot = await cachedCodexCapabilitiesBestEffort(
            command: "/definitely/missing/codex",
            paths: paths,
            ttlMs: Int.max,
            refreshTimeoutMs: 1
        )

        try expect(snapshot?.capabilities.version == "0.130.0", "best-effort capability lookup returns cached version")
        try expect(snapshot?.refreshed == false, "best-effort capability lookup does not refresh when cache exists")
    }

    private static func testOutboundSmokeTextEvidenceFindsMarkerInMessagesDb() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        try runSQLite(db, """
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered)
        VALUES (10, 'smoke-guid', 'hello CODEXMSGCTL_SMOKE_TEXT_TEST', 1, 0, 123);
        """)

        let evidence = try await outboundSmokeTextEvidence(marker: "CODEXMSGCTL_SMOKE_TEXT_TEST", afterRowId: 1, config: config)

        try expect(evidence?.rowId == 10, "smoke text evidence row id")
        try expect(evidence?.guid == "smoke-guid", "smoke text evidence guid")
        try expect(evidence?.dbError == 0, "smoke text evidence error")
        try expect(evidence?.dateDelivered == 123, "smoke text evidence delivered")
    }

    private static func testRecentFailedOutboundEvidenceFindsFailedTextAndAttachmentRows() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        try runSQLite(db, """
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered)
        VALUES (20, 'failed-text', 'failed outbound', 1, 42, 0);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered)
        VALUES (21, 'failed-attachment', '', 1, 0, 0);
        INSERT INTO attachment (ROWID, transfer_name, transfer_state)
        VALUES (5, 'probe.txt', 6);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (21, 5);
        """)

        let failures = try await recentFailedOutboundEvidence(config: config, limit: 5)

        try expect(failures.map(\.rowId) == [21, 20], "recent failures are newest first")
        try expect(failures.first?.attachmentName == "probe.txt", "failed attachment name")
        try expect(failures.first?.transferState == 6, "failed attachment transfer state")
        try expect(failures.last?.dbError == 42, "failed text error")
        try expect(formatRecentFailedOutboundEvidence(failures).contains("row 21"), "recent failure formatter includes row")
    }

    private static func testCodexAppServerProcessSnapshotParsesTransportsAndOrphans() throws {
        let snapshots = codexAppServerProcessSnapshots(from: """
          111     1   111 01-00:00:00 /opt/homebrew/bin/codex app-server --listen unix://
          222   200   200    00:01:00 /Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://
          333     1   300    00:02:00 /Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://
          444   400   400    00:00:10 /usr/bin/rg codex.*app-server
          555   500   500    00:00:03 /Applications/Codex.app/Contents/Resources/codex app-server --analytics-default-enabled
        """)

        try expect(snapshots.map(\.pid) == [111, 222, 333, 555], "app-server snapshot ignores non-codex helper commands")
        try expect(snapshots.map(\.transport) == ["unix", "stdio", "stdio", "desktop"], "app-server snapshot classifies transports")
        try expect(snapshots.filter(\.isOrphanedStdioTransport).map(\.pid) == [333], "app-server snapshot identifies orphaned stdio transport")
    }

    private static func testOutboundSmokeAttachmentEvidenceFindsMarkerInTransferName() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        try runSQLite(db, """
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered)
        VALUES (30, 'smoke-attachment-guid', '', 1, 0, 456);
        INSERT INTO attachment (ROWID, transfer_name, transfer_state)
        VALUES (7, 'codexmsgctl-smoke-CODEXMSGCTL_SMOKE_ATTACHMENT_TEST.png', 5);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (30, 7);
        """)

        let evidence = try await outboundSmokeAttachmentEvidence(marker: "CODEXMSGCTL_SMOKE_ATTACHMENT_TEST", afterRowId: 1, config: config)

        try expect(evidence?.rowId == 30, "smoke attachment evidence row id")
        try expect(evidence?.guid == "smoke-attachment-guid", "smoke attachment evidence guid")
        try expect(evidence?.attachmentName == "codexmsgctl-smoke-CODEXMSGCTL_SMOKE_ATTACHMENT_TEST.png", "smoke attachment evidence transfer name")
        try expect(evidence?.transferState == 5, "smoke attachment evidence transfer state")
    }

    private static func testOutboundSmokeAttachmentEvidenceFallsBackToLatestAttachment() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        try runSQLite(db, """
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered)
        VALUES (40, 'older-attachment-guid', '', 1, 0, 100);
        INSERT INTO attachment (ROWID, transfer_name, transfer_state)
        VALUES (8, 'older.png', 5);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (40, 8);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered)
        VALUES (41, 'clipboard-attachment-guid', '', 1, 0, 0);
        INSERT INTO attachment (ROWID, transfer_name, transfer_state)
        VALUES (9, 'IMG_0001.jpeg', 5);
        INSERT INTO message_attachment_join (message_id, attachment_id)
        VALUES (41, 9);
        """)

        let evidence = try await outboundSmokeAttachmentEvidence(marker: "CODEXMSGCTL_SMOKE_ATTACHMENT_MISSING_FROM_NAME", afterRowId: 40, config: config)

        try expect(evidence?.rowId == 41, "smoke attachment fallback row id")
        try expect(evidence?.attachmentName == "IMG_0001.jpeg", "smoke attachment fallback accepts Messages-renamed image")
        try expect(evidence?.detail == "matched latest outbound attachment after baseline", "smoke attachment fallback detail")
    }

    private static func testClipboardAttachmentSendRetriesWhenNoDbRowAppears() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        let countFile = paths.tmpDir.appendingPathComponent("fake-osascript-count")
        let image = paths.tmpDir.appendingPathComponent("probe.jpg")
        try Data([0xff, 0xd8, 0xff, 0xd9]).write(to: image)
        let script = paths.tmpDir.appendingPathComponent("fake-osascript.sh")
        try Data("""
        #!/bin/sh
        count_file=\(shellQuoted(countFile.path))
        db=\(shellQuoted(db.path))
        count=0
        if [ -f "$count_file" ]; then
          count=$(cat "$count_file")
        fi
        count=$((count + 1))
        printf "%s" "$count" > "$count_file"
        if [ "$count" -ge 2 ]; then
          /usr/bin/sqlite3 "$db" "INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered) VALUES (50, 'retry-attachment-guid', '', 1, 0, 0); INSERT INTO attachment (ROWID, transfer_name, transfer_state) VALUES (12, 'IMG_retry.jpeg', 5); INSERT INTO message_attachment_join (message_id, attachment_id) VALUES (50, 12);"
        fi
        exit 0
        """.utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let sink = AppleMessagesReplySink(
            osascriptCommand: script.path,
            messagesDbPath: db.path,
            attachmentVerificationTimeoutMs: 50,
            clipboardAttachmentAttempts: 2
        )

        let evidence = try await sink.sendAttachment(recipient: "+1-520-609-9095", service: "iMessage", filePath: image.path)

        try expect(evidence.dbRowId == 50, "clipboard attachment retry finds second-attempt row")
        try expect(evidence.detail?.contains("Succeeded after clipboard retry 2") == true, "clipboard attachment retry records retry detail")
        let attempts = try String(contentsOf: countFile, encoding: .utf8)
        try expect(attempts == "2", "clipboard attachment send retries exactly once after no-row failure")
    }

    private static func testCodexMentionExtraction() throws {
        let mentions = extractCodexMentionRefs(from: "Use [@Computer Use](plugin://computer-use@openai-bundled), @Chrome, plugin://chrome@openai-bundled, and app://google-calendar@openai-curated.")
        try expect(mentions.contains(CodexMentionRef(name: "Computer Use", path: "plugin://computer-use@openai-bundled")), "markdown plugin mention is extracted")
        try expect(mentions.contains(CodexMentionRef(name: "Chrome", path: "plugin://chrome@openai-bundled")), "bare Chrome mention is extracted and deduped against plugin URI")
        try expect(mentions.contains(CodexMentionRef(name: "google-calendar@openai-curated", path: "app://google-calendar@openai-curated")), "app URI mention is extracted")
        let chromeCount = mentions.filter { $0.path == "plugin://chrome@openai-bundled" }.count
        try expect(chromeCount == 1, "Chrome mention is deduplicated by path")
    }

    private static func testNaturalLanguageCodexMentionExtraction() throws {
        let mentions = extractCodexMentionRefs(from: "Please use Computer Use, then use Chrome, then use Browser.")
        try expect(mentions.contains(CodexMentionRef(name: "Computer Use", path: "plugin://computer-use@openai-bundled")), "natural language Computer Use mention is extracted")
        try expect(mentions.contains(CodexMentionRef(name: "Chrome", path: "plugin://chrome@openai-bundled")), "natural language Chrome mention is extracted")
        try expect(mentions.contains(CodexMentionRef(name: "Browser", path: "plugin://browser@openai-bundled")), "natural language Browser mention is extracted")
    }

    private static func testAppServerClientCapabilityInventory() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"userAgent":"codex-test","codexHome":"/tmp/.codex","platformFamily":"unix","platformOs":"macos"}}"#,
            #"{"id":2,"result":{"data":[{"cwd":"/tmp/project","skills":[{"name":"browser-use:browser","description":"Browser automation","path":"/skills/browser/SKILL.md","enabled":true},{"name":"disabled-skill","enabled":false}],"errors":[]}]}}"#,
            #"{"id":3,"result":{"marketplaces":[{"marketplaceName":"openai-bundled","summary":{"displayName":"OpenAI Bundled"},"skills":[{}],"apps":[{}],"mcpServers":["node_repl"]}],"marketplaceLoadErrors":[],"featuredPluginIds":[]}}"#,
            #"{"id":4,"result":{"data":[{"id":"connector_1","name":"Notion","description":"Create docs","isAccessible":true,"isEnabled":true,"pluginDisplayNames":["Notion"],"labels":{"consequential":"true"}}],"nextCursor":null}}"#,
            #"{"id":5,"result":{"data":[{"name":"node_repl","tools":{"js":{"name":"js","inputSchema":{}}},"resources":[],"resourceTemplates":[],"authStatus":"ready"}],"nextCursor":null}}"#
        ])
        let client = CodexAppServerClient(timeoutMs: 1_000) { fake }
        let inventory = try await client.capabilityInventory(cwd: "/tmp/project", forceReload: true)

        try expect(fake.sentMethods == ["initialize", "initialized", "skills/list", "plugin/list", "app/list", "mcpServerStatus/list"], "capability inventory calls app-server list methods")
        try expect(inventory.skills.map(\.name) == ["browser-use:browser", "disabled-skill"], "inventory parses skills")
        try expect(inventory.enabledSkillCount == 1, "inventory counts enabled skills")
        try expect(inventory.plugins.first?.displayName == "OpenAI Bundled", "inventory parses plugins")
        try expect(inventory.apps.first?.name == "Notion", "inventory parses apps")
        try expect(inventory.apps.first?.labels["consequential"] == "true", "inventory preserves app labels")
        try expect(inventory.mcpServers.first?.toolCount == 1, "inventory parses MCP tools")
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

    private static func testAutomationDirectiveStripping() throws {
        let text = """
        Morning Digest
        Bring an umbrella.
        ::inbox-item{title="Morning digest" summary="Review highlights"}
        """
        try expect(sanitizedAutomationMessage(text) == "Morning Digest\nBring an umbrella.", "automation forwarding strips Codex-only directives")
    }

    private static func testSmsUrlRecipientNormalizesPhoneNumbers() throws {
        try expect(smsURLRecipient("+1-520-609-9095") == "+15206099095", "sms URL phone recipient strips separators")
        try expect(smsURLRecipient("520 609 9095") == "5206099095", "sms URL phone recipient preserves bare number")
        try expect(smsURLRecipient("person@example.com") == "person@example.com", "sms URL recipient preserves emails")
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

    private static func testAppServerTimeoutTerminatesChildProcesses() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let script = paths.tmpDir.appendingPathComponent("fake-app-server-with-child.sh")
        let childPidFile = paths.tmpDir.appendingPathComponent("child.pid")
        let scriptText = """
        #!/bin/sh
        /bin/sleep 60 &
        echo "$!" > "\(childPidFile.path)"
        while IFS= read -r line; do
          case "$line" in
            *'"id":1'*)
              printf '%s\\n' '{"id":1,"result":{"ok":true}}'
              ;;
            *'"thread/start"'*)
              /bin/sleep 60
              ;;
          esac
        done
        """
        try scriptText.write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        var config = defaultBridgeConfig(paths: paths, codexCommand: script.path)
        config.timeoutMs = 500
        do {
            _ = try await CodexAppServerBackend(config: config, paths: paths).invoke(
                PromptRequest(promptText: "timeout", attachments: []),
                sessionId: nil,
                onEvent: nil
            )
            throw TestFailure(description: "Expected app-server timeout")
        } catch let error as CodexBackendFailure {
            try expect(error.timedOut, "app-server timeout is reported")
        }
        let childPidText = try String(contentsOf: childPidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let childPid = try expectInt32(childPidText)
        try expectEventuallyProcessExits(pid: childPid, timeoutSeconds: 3, "app-server timeout closes process tree")
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

    private static func testAppServerBackendUsesReadOnlySandboxForAutomationRequests() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-automation","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-automation"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-automation","turnId":"turn-automation","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"I would use the Codex automation tool if available."}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-automation","turn":{"id":"turn-automation","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        _ = try await backend.invoke(PromptRequest(promptText: "Create an automation to send me a daily digest every morning.", attachments: []), sessionId: nil, onEvent: nil)

        let turnStart = fake.sentMessages.first { $0["method"] as? String == "turn/start" }
        let params = turnStart?["params"] as? [String: Any]
        let sandboxPolicy = params?["sandboxPolicy"] as? [String: Any]
        try expect(sandboxPolicy?["type"] as? String == "readOnly", "automation requests use read-only app-server sandbox")
    }

    private static func testAppServerBackendAddsCapabilityInventoryToDeveloperInstructions() async throws {
        let paths = testPaths()
        try writeCapabilityCacheWithInventory(paths: paths)
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-inventory","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-inventory"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-inventory","turnId":"turn-inventory","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"Done."}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-inventory","turn":{"id":"turn-inventory","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: paths) { fake }

        _ = try await backend.invoke(PromptRequest(promptText: "Use @Chrome to inspect the current tab.", attachments: []), sessionId: nil, onEvent: nil)

        let threadStart = fake.sentMessages.first { $0["method"] as? String == "thread/start" }
        let params = threadStart?["params"] as? [String: Any]
        let instructions = params?["developerInstructions"] as? String ?? ""
        try expect(instructions.contains("Current Codex capability inventory from app-server cache"), "developer instructions include cached capability inventory")
        try expect(instructions.contains("Browser"), "developer instructions include accessible app inventory")
        try expect(instructions.contains("chrome:Chrome"), "developer instructions include enabled skill inventory")
        try expect(instructions.contains("Invocation status: Chrome: callable"), "developer instructions distinguish callable capability status")
    }

    private static func testAppServerBackendAddsStructuredMentionsToTurnInput() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-mentions","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-mentions"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-mentions","turnId":"turn-mentions","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"mentions received"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-mentions","turn":{"id":"turn-mentions","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        _ = try await backend.invoke(
            PromptRequest(promptText: "Use [@Computer Use](plugin://computer-use@openai-bundled), then @Chrome.", attachments: []),
            sessionId: nil,
            onEvent: nil
        )

        let turnStart = fake.sentMessages.first { $0["method"] as? String == "turn/start" }
        let params = turnStart?["params"] as? [String: Any]
        let input = params?["input"] as? [[String: Any]] ?? []
        try expect(input.first?["type"] as? String == "text", "turn input preserves original text first")
        try expect(input.first?["text"] as? String == "Use [@Computer Use](plugin://computer-use@openai-bundled), then @Chrome.", "turn input does not rewrite visible prompt text")
        let mentions = input.filter { $0["type"] as? String == "mention" }
        try expect(mentions.contains { $0["name"] as? String == "Computer Use" && $0["path"] as? String == "plugin://computer-use@openai-bundled" }, "turn input includes Computer Use mention metadata")
        try expect(mentions.contains { $0["name"] as? String == "Chrome" && $0["path"] as? String == "plugin://chrome@openai-bundled" }, "turn input includes Chrome mention metadata")
    }

    private static func testAppServerBackendRejectsNonFinalAgentMessageAsReply() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-no-final","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-no-final"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-no-final","turnId":"turn-no-final","item":{"type":"agentMessage","id":"item-summary","status":"completed","text":"Summary from source + live runtime check: internal sub-agent summary"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-no-final","turn":{"id":"turn-no-final","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        do {
            _ = try await backend.invoke(PromptRequest(promptText: "create an automation", attachments: []), sessionId: nil, onEvent: nil)
            throw TestFailure(description: "Expected app-server backend to reject missing final answer")
        } catch let error as CodexBackendFailure {
            try expect(error.message == "Codex app-server completed without a final reply.", "missing final answer produces bridge failure")
            try expect(!error.message.contains("Summary from source"), "non-final agent summary is not returned as failure message")
            try expect(fake.closed, "app-server backend closes connection after missing final answer")
        }
    }

    private static func testAppServerBackendForwardsDynamicToolRequests() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-tool","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-tool"}}}"#,
            #"{"id":99,"method":"item/tool/call","params":{"threadId":"thread-tool","turnId":"turn-tool","callId":"call-1","namespace":"mcp__node_repl__","tool":"js","arguments":{"code":"nodeRepl.write('ok')"}}}"#,
            #"{"id":4,"result":{"content":[{"type":"text","text":"ok from node"}],"isError":false}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-tool","turnId":"turn-tool","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"tool done"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-tool","turn":{"id":"turn-tool","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        let response = try await backend.invoke(PromptRequest(promptText: "Use @Chrome to run the same node_repl path native Codex uses.", attachments: []), sessionId: nil, onEvent: nil)

        try expect(response.text == "tool done", "dynamic tool forwarding still allows final answer")
        try expect(fake.sentMethods.contains("mcpServer/tool/call"), "dynamic tool request is forwarded to MCP app-server method")
        let mcpRequest = fake.sentMessages.first { $0["method"] as? String == "mcpServer/tool/call" }
        let mcpParams = mcpRequest?["params"] as? [String: Any]
        try expect(mcpParams?["threadId"] as? String == "thread-tool", "forwarded MCP request keeps thread id")
        try expect(mcpParams?["server"] as? String == "node_repl", "Chrome/node_repl namespace maps to node_repl MCP server")
        try expect(mcpParams?["tool"] as? String == "js", "forwarded MCP request keeps tool name")
        let arguments = mcpParams?["arguments"] as? [String: Any]
        try expect(arguments?["code"] as? String == "nodeRepl.write('ok')", "forwarded MCP request keeps tool arguments")
        let toolReply = fake.sentMessages.first { ($0["id"] as? Int) == 99 }
        let result = toolReply?["result"] as? [String: Any]
        try expect(result?["success"] as? Bool == true, "dynamic tool response reports success")
        let contentItems = result?["contentItems"] as? [[String: Any]] ?? []
        try expect(contentItems.contains { $0["type"] as? String == "inputText" && $0["text"] as? String == "ok from node" }, "dynamic tool response converts MCP text content")
    }

    private static func testAppServerBackendRejectsUnsupportedDynamicToolNamespace() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-tool","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-tool"}}}"#,
            #"{"id":90,"method":"item/tool/call","params":{"threadId":"thread-tool","turnId":"turn-tool","callId":"call-unsupported","namespace":"plugin://chrome","tool":"current_tab","arguments":{}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-tool","turnId":"turn-tool","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"unsupported namespace handled"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-tool","turn":{"id":"turn-tool","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        let response = try await backend.invoke(PromptRequest(promptText: "Use a non-MCP dynamic tool.", attachments: []), sessionId: nil, onEvent: nil)

        try expect(response.text == "unsupported namespace handled", "unsupported dynamic namespace still allows final answer")
        try expect(!fake.sentMethods.contains("mcpServer/tool/call"), "unsupported dynamic namespace is not forwarded to MCP")
        let toolReply = fake.sentMessages.first { ($0["id"] as? Int) == 90 }
        let result = toolReply?["result"] as? [String: Any]
        let contentItems = result?["contentItems"] as? [[String: Any]] ?? []
        try expect(result?["success"] as? Bool == false, "unsupported dynamic namespace reports failure")
        try expect(contentItems.contains { ($0["text"] as? String)?.contains("only execute MCP-backed dynamic tools") == true }, "unsupported dynamic namespace explains bridge boundary")
    }

    private static func testAppServerBackendHandlesMalformedDynamicToolRequest() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-tool","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-tool"}}}"#,
            #"{"id":91,"method":"item/tool/call","params":{"threadId":"thread-tool","namespace":"mcp__node_repl__","arguments":{}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-tool","turnId":"turn-tool","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"malformed tool handled"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-tool","turn":{"id":"turn-tool","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        let response = try await backend.invoke(PromptRequest(promptText: "Use a malformed dynamic tool.", attachments: []), sessionId: nil, onEvent: nil)

        try expect(response.text == "malformed tool handled", "malformed dynamic tool still allows final answer")
        try expect(!fake.sentMethods.contains("mcpServer/tool/call"), "malformed dynamic tool is not forwarded to MCP")
        let toolReply = fake.sentMessages.first { ($0["id"] as? Int) == 91 }
        let result = toolReply?["result"] as? [String: Any]
        let contentItems = result?["contentItems"] as? [[String: Any]] ?? []
        try expect(result?["success"] as? Bool == false, "malformed dynamic tool reports failure")
        try expect(contentItems.contains { ($0["text"] as? String)?.contains("missing required thread/tool fields") == true }, "malformed dynamic tool explains missing fields")
    }

    private static func testAppServerBackendNormalizesOddDynamicToolResponses() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-tool","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-tool"}}}"#,
            #"{"id":92,"method":"item/tool/call","params":{"threadId":"thread-tool","turnId":"turn-tool","callId":"call-odd","namespace":"mcp__node_repl__","tool":"js","arguments":{"code":"odd()"}}}"#,
            #"{"id":4,"result":{"content":[{"type":"image","url":"file:///tmp/tool.png"},{"type":"json","payload":{"ok":true}},17],"isError":true}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-tool","turnId":"turn-tool","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"odd tool handled"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-tool","turn":{"id":"turn-tool","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        let response = try await backend.invoke(PromptRequest(promptText: "Use an odd dynamic tool.", attachments: []), sessionId: nil, onEvent: nil)

        try expect(response.text == "odd tool handled", "odd dynamic tool response still allows final answer")
        let toolReply = fake.sentMessages.first { ($0["id"] as? Int) == 92 }
        let result = toolReply?["result"] as? [String: Any]
        let contentItems = result?["contentItems"] as? [[String: Any]] ?? []
        try expect(result?["success"] as? Bool == false, "MCP isError maps to unsuccessful dynamic response")
        try expect(contentItems.contains { $0["type"] as? String == "inputImage" && $0["imageUrl"] as? String == "file:///tmp/tool.png" }, "dynamic tool response preserves image content")
        try expect(contentItems.contains { ($0["text"] as? String)?.contains("payload") == true }, "dynamic tool response stringifies unknown object content")
        try expect(contentItems.contains { $0["type"] as? String == "inputText" && $0["text"] as? String == "17" }, "dynamic tool response stringifies primitive content")
    }

    private static func testAppServerBackendResolvesInteractiveCallbacksWithResponder() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-prompts","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-prompts"}}}"#,
            #"{"id":70,"method":"item/tool/requestUserInput","params":{"threadId":"thread-prompts","turnId":"turn-prompts","itemId":"item-input","questions":[{"id":"choice","header":"Pick","question":"Choose one","isOther":false,"isSecret":false,"options":[{"label":"A","description":"first"},{"label":"B","description":"second"}]}]}}"#,
            #"{"id":71,"method":"mcpServer/elicitation/request","params":{"threadId":"thread-prompts","turnId":null,"serverName":"codex_apps","mode":"form","message":"Need confirmation","requestedSchema":{"type":"object","properties":{"confirmed":{"type":"boolean"}}}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-prompts","turnId":"turn-prompts","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"prompt callbacks resolved"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-prompts","turn":{"id":"turn-prompts","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let callbackMethods = StringCollector()
        let backend = CodexAppServerBackend(
            config: config,
            paths: testPaths(),
            interactiveCallbackResponder: { method, _, _ in
                callbackMethods.append(method)
                if method == "item/tool/requestUserInput" {
                    return ["result": ["answers": ["choice": ["answers": ["B"]]]]]
                }
                return ["result": ["action": "accept", "content": ["confirmed": true], "_meta": NSNull()]]
            },
            makeConnection: { fake }
        )

        let response = try await backend.invoke(PromptRequest(promptText: "Exercise structured prompt callbacks.", attachments: []), sessionId: nil, onEvent: nil)

        try expect(response.text == "prompt callbacks resolved", "interactive callbacks still allow final answer")
        try expect(callbackMethods.snapshot() == ["item/tool/requestUserInput", "mcpServer/elicitation/request"], "interactive callback responder sees both methods")
        let inputReply = fake.sentMessages.first { ($0["id"] as? Int) == 70 }
        let inputResult = inputReply?["result"] as? [String: Any]
        let answers = inputResult?["answers"] as? [String: Any]
        try expect(answers?["choice"] != nil, "requestUserInput sends responder answers")
        let elicitationReply = fake.sentMessages.first { ($0["id"] as? Int) == 71 }
        let elicitationResult = elicitationReply?["result"] as? [String: Any]
        try expect(elicitationResult?["action"] as? String == "accept", "elicitation sends responder result")
    }

    private static func testAppServerBackendBlocksUserInputAndElicitationRequests() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-prompts","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-prompts"}}}"#,
            #"{"id":70,"method":"item/tool/requestUserInput","params":{"threadId":"thread-prompts","turnId":"turn-prompts","itemId":"item-input","prompt":"Choose one"}}"#,
            #"{"id":71,"method":"mcpServer/elicitation/request","params":{"threadId":"thread-prompts","server":"codex_apps","request":{"message":"Need confirmation"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-prompts","turnId":"turn-prompts","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"prompt callbacks resolved"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-prompts","turn":{"id":"turn-prompts","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }
        let eventCollector = CodexEventCollector()

        do {
            _ = try await backend.invoke(PromptRequest(promptText: "Exercise structured prompt callbacks.", attachments: []), sessionId: nil) { event in
                eventCollector.append(event)
            }
            throw TestFailure(description: "Expected app-server prompt callbacks to block the bridge")
        } catch let error as CodexBackendFailure {
            try expect(error.message.contains("requires interactive user input that the Messages bridge cannot answer"), "requestUserInput produces explicit bridge failure")
        }
        let inputReply = fake.sentMessages.first { ($0["id"] as? Int) == 70 }
        let inputError = inputReply?["error"] as? [String: Any]
        try expect((inputError?["message"] as? String)?.contains("requires interactive user input") == true, "requestUserInput replies with explicit JSON-RPC error")
        try expect(!fake.sentMessages.contains { ($0["id"] as? Int) == 71 }, "bridge stops before silently cancelling elicitation")
        let blockers = eventCollector.snapshot().filter { event in
            if case .blocker = event { return true }
            return false
        }
        try expect(blockers.count == 1, "requestUserInput emits a visible blocker event")
    }

    private static func testBridgeDefaultBackendInteractiveCallbackEndToEnd() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.timeoutMs = 5_000
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-start-callback", text: "Trigger the callback test.", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            makeDefaultCodex: { _, responder in ResponderCodexBackend(responder: responder) },
            useDefaultCodexBackend: true,
            now: Date.init
        )

        try await service.initialize()
        try await service.tick()
        let callbackPromptReplies = try await waitForReplies(sink, count: 1)
        try expect(callbackPromptReplies.first?.text.contains("Codex needs your input to continue:") == true, "default backend sends callback prompt")
        try expect(callbackPromptReplies.first?.text.contains("Choose a test answer") == true, "callback prompt includes app-server question")

        source.append(MessageItem(rowId: 2, guid: "guid-answer-callback", text: "blue", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:01.000Z", attachments: []))
        try await service.tick()
        let replies = try await waitForReplies(sink, count: 3)
        try expect(replies.contains { $0.text == "Got it. I captured that reply for the pending Codex prompt." }, "callback answer is acknowledged")
        try expect(replies.contains { $0.text == "Callback completed with blue." }, "original Codex turn resumes and sends final answer")
        let state = try await waitForState(stores, timeout: 3) { state in
            state.pendingInteractiveCallback == nil && state.activeJob == nil
        }
        try expect(state.pendingInteractiveCallback == nil, "completed callback clears pending callback state")
        try expect(state.activeJob == nil, "completed callback turn clears active job")
        try expect(state.codexSession.sessionId == "thread-callback", "callback turn preserves Codex thread id")
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

    private static func testOutgoingAttachmentIntentGate() throws {
        try expect(!outgoingAttachmentsWereRequested(in: "Sending you an App Store Connect api key, can you move it over to your Developer folder?"), "incoming file transfer is not an outgoing attachment request")
        try expect(!outgoingAttachmentsWereRequested(in: "Create an article from this page and save it to disk"), "save-to-disk request is not an outgoing attachment request")
        try expect(outgoingAttachmentsWereRequested(in: "Can you send me the generated PNG when you're done?"), "send me asks for outgoing attachment")
        try expect(outgoingAttachmentsWereRequested(in: "Can you grab a random image and send it over to me?"), "send it over asks for outgoing attachment")
        try expect(outgoingAttachmentsWereRequested(in: "Please send over the image when it is ready."), "send over asks for outgoing attachment")
        try expect(outgoingAttachmentsWereRequested(in: "Please return the file as an attachment"), "return as attachment asks for outgoing attachment")
    }

    private static func testBridgeAttachDirectiveAlwaysSendsValidatedAttachment() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.outgoingAttachmentMode = "fullAccess"
        try stores.config.save(config)

        let attachment = paths.stateDir.appendingPathComponent("generated.png")
        try Data("image".utf8).write(to: attachment)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-attach", text: "make the picture", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "Done.\nBRIDGE_ATTACH: \(attachment.path)") },
            now: { Date(timeIntervalSince1970: 1_777_777_777) }
        )

        try await service.initialize()
        try await service.tick()
        for _ in 0..<40 {
            if await sink.attachmentsSnapshot().count >= 1 { break }
            try await Task.sleep(nanoseconds: 25_000_000)
        }

        let replies = await sink.repliesSnapshot()
        let attachments = await sink.attachmentsSnapshot()
        try expect(replies.map(\.text) == ["Done."], "visible attachment directive is stripped from text")
        try expect(attachments.map(\.filePath) == [attachment.path], "validated BRIDGE_ATTACH path sends even without prompt heuristics")
        let state = try stores.state.load()
        try expect(state.lastOutboundSend?.kind == "attachment", "last outbound send records attachment kind")
        try expect(state.lastOutboundSend?.status == "dbObserved", "last outbound send records database observation")
        try expect(service.runLocalCommand("/status").contains("Last outbound send: attachment dbObserved"), "status exposes outbound send evidence")
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

    private static func testDeadActiveJobOnStartupNotifiesAndClears() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        try stores.state.save(BridgeState(
            lastProcessedGuid: nil,
            lastProcessedRowId: 0,
            pendingBatch: nil,
            activeJob: ActiveJob(
                jobId: "dead-job",
                guid: "dead-guid",
                rowId: 42,
                type: "promptBatch",
                receivedAt: "2026-05-22T04:58:29.095Z",
                promptPreview: "status question",
                recipient: "+1",
                service: "iMessage",
                startedAt: "2026-05-22T04:58:29.095Z",
                lastProgressAt: nil,
                lastUserUpdateAt: nil,
                lastEventAt: "2026-05-22T04:59:56.047Z",
                codexPid: 999_999,
                codexSessionId: "thread-dead",
                outputPath: nil,
                sessionLogPath: nil,
                status: "running",
                lastObservedSummary: "Started a command that was later interrupted.",
                permissionRecoveryAttempts: 0,
                waitingForPermissionSince: nil,
                lastPermissionEventId: nil
            ),
            codexSession: CodexSessionState(sessionId: "thread-dead", startedAt: nil, lastPromptAt: nil, lastCompletedAt: nil, expiresAt: nil, lastErrorAt: nil)
        ))
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in QueueMessageSource(messages: []) },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "unused") },
            now: { Date(timeIntervalSince1970: 1_779_426_100) }
        )

        try await service.initialize()
        try await service.tick()

        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text) == ["That active job stopped before it could finish, so I cleared it. Please send the request again."], "dead startup job sends a visible recovery notice")
        let state = try stores.state.load()
        try expect(state.activeJob == nil, "dead startup job is cleared after notification")
    }

    private static func testPendingInteractiveCallbackCapturesNextReply() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        var state = defaultBridgeState()
        state.pendingInteractiveCallback = PendingInteractiveCallback(
            callbackId: "callback-1",
            jobId: "job-1",
            jsonRpcId: "70",
            method: "item/tool/requestUserInput",
            recipient: "+1",
            service: "iMessage",
            prompt: "Choose one",
            createdAt: "2026-01-01T00:00:00.000Z",
            expiresAt: "2026-01-01T00:05:00.000Z",
            status: "pending"
        )
        try stores.state.save(state)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "callback-answer", text: "Use option B", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:01.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            now: { Date(timeIntervalSince1970: 1_767_225_602) }
        )

        try await service.initialize()
        try await service.tick()

        let reloaded = try stores.state.load()
        try expect(reloaded.pendingInteractiveCallback?.status == "answered", "pending callback records answered status")
        try expect(reloaded.pendingInteractiveCallback?.responseText == "Use option B", "pending callback records Messages reply text")
        try expect(reloaded.pendingInteractiveCallback?.responseRowId == 1, "pending callback records reply row")
        try expect(reloaded.pendingBatch == nil, "callback reply is not queued as a new prompt batch")
        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text) == ["Got it. I captured that reply for the pending Codex prompt."], "callback reply sends visible acknowledgement")
    }

    private static func testPendingInteractiveCallbackCancelAndTimeout() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        var state = defaultBridgeState()
        state.pendingInteractiveCallback = PendingInteractiveCallback(
            callbackId: "callback-cancel",
            method: "item/tool/requestUserInput",
            recipient: "+1",
            service: "iMessage",
            prompt: "Choose one",
            createdAt: "2026-01-01T00:00:00.000Z",
            expiresAt: "2026-01-01T00:05:00.000Z",
            status: "pending"
        )
        try stores.state.save(state)
        let cancelSink = CapturingReplySink()
        let cancelService = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in QueueMessageSource(messages: [
                MessageItem(rowId: 1, guid: "cancel", text: "/cancel", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:01.000Z", attachments: [])
            ]) },
            makeReplySink: { _ in cancelSink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            now: { Date(timeIntervalSince1970: 1_767_225_602) }
        )
        try await cancelService.initialize()
        try await cancelService.tick()
        let canceledState = try stores.state.load()
        try expect(canceledState.pendingInteractiveCallback == nil, "cancel clears pending callback")
        let cancelReplies = await cancelSink.repliesSnapshot()
        try expect(cancelReplies.map(\.text) == ["Canceled the pending Codex prompt."], "cancel callback sends visible reply")

        var timeoutState = canceledState
        timeoutState.lastProcessedRowId = 1
        timeoutState.pendingInteractiveCallback = PendingInteractiveCallback(
            callbackId: "callback-timeout",
            method: "mcpServer/elicitation/request",
            recipient: "+1",
            service: "iMessage",
            prompt: "Confirm",
            createdAt: "2026-01-01T00:00:00.000Z",
            expiresAt: "2026-01-01T00:00:01.000Z",
            status: "pending"
        )
        try stores.state.save(timeoutState)
        let timeoutSink = CapturingReplySink()
        let timeoutService = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in QueueMessageSource(messages: []) },
            makeReplySink: { _ in timeoutSink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "should not run") },
            now: { Date(timeIntervalSince1970: 1_767_225_610) }
        )
        try await timeoutService.initialize()
        try await timeoutService.tick()
        let timedOutState = try stores.state.load()
        try expect(timedOutState.pendingInteractiveCallback == nil, "timeout clears pending callback")
        let timeoutReplies = await timeoutSink.repliesSnapshot()
        try expect(timeoutReplies.map(\.text) == ["The pending Codex prompt timed out waiting for your reply."], "timeout sends visible reply")
    }

    private static func testCorruptedStateJsonBacksUpAndDefaults() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        try "{".write(to: paths.statePath, atomically: true, encoding: .utf8)
        let stores = RuntimeStores(paths: paths)

        let state = try stores.state.load()

        try expect(state.lastProcessedRowId == 0, "corrupted state falls back to default state")
        let backups = try FileManager.default.contentsOfDirectory(atPath: paths.stateDir.path)
            .filter { $0.hasPrefix("state.json.corrupt-") }
        try expect(!backups.isEmpty, "corrupted state is backed up for diagnosis")
    }

    private static func testStateRecoveryBackupDiagnosticsReportBackupPath() throws {
        let paths = testPaths()
        try FileManager.default.createDirectory(at: paths.stateDir, withIntermediateDirectories: true)
        let older = paths.stateDir.appendingPathComponent("state.json.corrupt-1000")
        let newer = paths.stateDir.appendingPathComponent("state.json.corrupt-2000")
        try Data("older".utf8).write(to: older)
        try Data("newer".utf8).write(to: newer)

        let backups = recentStateRecoveryBackups(paths: paths, limit: 1)

        try expect(stateRecoveryBackupCount(paths: paths) == 2, "state recovery backup count")
        try expect(backups.map(\.path) == [newer.path], "state recovery diagnostics report latest backup path")
    }

    private static func testLaunchAgentProgramDiagnostics() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let helperPath = paths.tmpDir.appendingPathComponent("Helper With Spaces")
        try Data("#!/bin/sh\n".utf8).write(to: helperPath)
        let plistData = try helperLaunchAgentPlistData(paths: paths, helperExecutable: helperPath)
        try FileManager.default.createDirectory(at: paths.launchAgentsDir, withIntermediateDirectories: true)
        try plistData.write(to: paths.helperLaunchAgentPath)
        let launchctlOutput = """
        gui/501/com.moss.MessagesCodexBridge.Helper = {
            state = running

            program = \(helperPath.path)
            arguments = {
                \(helperPath.path)
            }
        }
        """

        try expect(launchAgentProgramArgument(at: paths.helperLaunchAgentPath) == helperPath.path, "launchagent plist program argument")
        try expect(launchctlProgram(from: launchctlOutput) == helperPath.path, "launchctl loaded program parser")
    }

    private static func testAutomationRequestCreatesCodexAutomationFromInterpretedSpec() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-auto", text: "Can we create a new automation? Every morning at 7am, send a small morning digest.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-12T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in
                FakeProgressCodexBackend(
                    events: [],
                    response: """
                    {"name":"Morning News and Weather Digest","prompt":"Create a concise morning digest for the user in Brooklyn/NYC. Gather current information from reliable sources and include local news, American news, AI news, technology news, breaking news, weather and clothing advice, and interesting x.com threads. Use Chrome or Computer Use when available.","rrule":"FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0","model":"gpt-5.2","reasoningEffort":"medium","executionEnvironment":"local","cwds":["/Users/moss/Developer/Codex Misc"]}
                    """
                )
            },
            now: { Date(timeIntervalSince1970: 1_778_640_000) }
        )

        try await service.initialize()
        try await service.tick()
        try await Task.sleep(nanoseconds: 50_000_000)
        try await service.tick()

        let replies = await sink.repliesSnapshot()
        try expect(replies.count == 1, "automation request gets one creation reply")
        let reply = try expectReply(replies.first)
        try expect(reply.text.contains("Created Codex automation: Morning News and Weather Digest"), "automation reply confirms interpreted creation")
        let toml = try String(contentsOf: paths.codexAutomationsDir.appendingPathComponent("morning-news-and-weather-digest/automation.toml"), encoding: .utf8)
        try expect(toml.contains(#"rrule = "FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0""#), "service-created automation has interpreted morning schedule")
        try expect(toml.contains("Create a concise morning digest for the user"), "service-created automation uses interpreted prompt")
        try expect(!toml.contains("Can we create a new automation?"), "service-created automation does not paste raw request")
        let state = try stores.state.load()
        try expect(state.activeJob == nil, "automation creation does not start Codex job")
        try expect(state.codexSession.sessionId == nil, "automation creation does not mutate Codex session")
        try expect(state.automationCreationStatus?.phase == "confirmed", "automation creation status records confirmation")
        try expect(state.automationCreationStatus?.createdFilePath?.hasSuffix("automation.toml") == true, "automation creation status records file path")
        let route = try expectRoute(state.automationRoutes?.first)
        try expect(route.automationId == "morning-news-and-weather-digest", "automation route id persisted")
        try expect(route.recipient == "+1", "automation route recipient comes from Messages batch")
        try expect(route.service == "iMessage", "automation route service comes from Messages batch")
        try expect(route.createdFromGuid == "guid-auto", "automation route source guid persisted")
    }

    private static func testCodexAutomationsReportsCreationInProgress() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        var state = defaultBridgeState()
        state.automationCreationStatus = AutomationCreationStatus(
            name: "Bridge Smoke Test",
            sourceRowId: 725,
            sourceGuid: "guid-smoke",
            phase: "creating",
            updatedAt: "2026-05-22T00:00:00.000Z"
        )
        try stores.state.save(state)
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in QueueMessageSource(messages: []) },
            makeReplySink: { _ in CapturingReplySink() },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "unused") }
        )

        try await service.initialize()
        let text = service.runLocalCommand("/codex automations")

        try expect(text.contains("Automation creation creating: Bridge Smoke Test"), "/codex automations reports in-flight creation")
        try expect(text.contains("Source row: 725"), "/codex automations includes source row")
    }

    private static func testCompletedAutomationSessionIsForwardedOnce() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        try stores.state.save(BridgeState(
            lastProcessedGuid: nil,
            lastProcessedRowId: 0,
            pendingBatch: nil,
            activeJob: nil,
            codexSession: CodexSessionState(),
            automationRoutes: [
                CodexAutomationRoute(
                    automationId: "morning-news-and-weather-digest",
                    name: "Morning News and Weather Digest",
                    recipient: "+1",
                    service: "iMessage",
                    createdFromGuid: "guid-auto",
                    createdFromRowId: 1,
                    createdAt: "2026-05-12T00:00:00.000Z"
                )
            ]
        ))
        try writeAutomationSessionFixture(paths: paths)
        let sink = CapturingReplySink()
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in QueueMessageSource(messages: []) },
            makeReplySink: { _ in sink },
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "unused") },
            now: { Date(timeIntervalSince1970: 1_778_650_000) }
        )

        try await service.initialize()
        try await service.tick()
        try await service.tick()

        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text) == ["Morning Digest\nBring an umbrella."], "completed automation final answer is forwarded once")
        let state = try stores.state.load()
        let route = try expectRoute(state.automationRoutes?.first)
        try expect(route.lastSeenSessionId == "019e20ff-4dca-7571-9425-0713bddb0d73", "route records seen session")
        try expect(route.lastDeliveredSessionId == "019e20ff-4dca-7571-9425-0713bddb0d73", "route records delivered session")
    }

    private static func testCompletedAutomationScanUsesDeliveredSessionLowerBound() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let route = CodexAutomationRoute(
            automationId: "morning-news-and-weather-digest",
            name: "Morning News and Weather Digest",
            recipient: "+1",
            service: "iMessage",
            createdFromGuid: "guid-auto",
            createdFromRowId: 1,
            createdAt: "2026-05-12T00:00:00.000Z",
            lastSeenSessionId: "019e20ff-4dca-7571-9425-0713bddb0d73",
            lastDeliveredSessionId: "019e20ff-4dca-7571-9425-0713bddb0d73",
            lastDeliveredAt: "2026-05-13T11:05:16.869Z"
        )
        let dir = paths.codexSessionsDir.appendingPathComponent("2026/05/13")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let oldPayload = Data(repeating: 120, count: 64 * 1024)
        for index in 0..<80 {
            let sessionId = String(format: "019e20fe-0000-7000-8000-%012x", index)
            let file = dir.appendingPathComponent("rollout-2026-05-13T06-59-\(String(format: "%02d", index % 60))-\(sessionId).jsonl")
            try oldPayload.write(to: file, options: .atomic)
        }

        let newSessionId = "019e2100-0000-7000-8000-000000000001"
        let newFile = dir.appendingPathComponent("rollout-2026-05-13T07-06-00-\(newSessionId).jsonl")
        let newPayload = Data("""
        {"timestamp":"2026-05-13T11:06:00.000Z","type":"session_meta","payload":{"id":"\(newSessionId)"}}
        {"timestamp":"2026-05-13T11:06:01.000Z","type":"event_msg","payload":{"type":"user_message","message":"Automation ID: morning-news-and-weather-digest"}}
        {"timestamp":"2026-05-13T11:06:02.000Z","type":"event_msg","payload":{"type":"task_complete","last_agent_message":"Fresh digest"}}

        """.utf8)
        try newPayload.write(to: newFile, options: .atomic)

        let scan = completedCodexAutomationRunScan(
            in: paths.codexSessionsDir,
            routes: [route],
            options: CodexAutomationScanOptions(
                maximumFilesToRead: 1
            )
        )

        try expect(scan.candidateFileCount == 81, "scan sees all candidate rollout files")
        try expect(scan.skippedFileCount == 80, "scan skips delivered historical sessions without reading them")
        try expect(scan.readFileCount == 1, "scan reads only the new session inside the read budget")
        try expect(scan.runs.map(\.sessionId) == [newSessionId], "scan finds new automation result after lower bound")
        try expect(scan.runs.first?.message == "Fresh digest", "scan parses fresh automation message")
    }

    private static func testTerminateProcessTreeIncludesRoot() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "/bin/sleep 60 & wait"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        defer {
            if process.isRunning { process.terminate() }
        }
        Thread.sleep(forTimeInterval: 0.2)

        let result = terminateProcessTree(rootPid: process.processIdentifier)

        try expect(result.rootPid == process.processIdentifier, "process cleanup records root pid")
        try expect(result.terminatedPids.contains(process.processIdentifier), "process cleanup terminates root pid")
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
            makeCodex: { _ in FakeProgressCodexBackend(events: [], response: "unused") },
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

    private static func expectPath(_ path: String?) throws -> String {
        guard let path else {
            throw TestFailure(description: "Expected path")
        }
        return path
    }

    private static func expectInt32(_ value: String) throws -> Int32 {
        guard let parsed = Int32(value) else {
            throw TestFailure(description: "Expected Int32 value, got \(value)")
        }
        return parsed
    }

    private static func expectEventuallyProcessExits(pid: Int32, timeoutSeconds: Double, _ message: String) throws {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if !processIsRunningForTest(pid) { return }
            Thread.sleep(forTimeInterval: 0.05)
        }
        throw TestFailure(description: message)
    }

    private static func processIsRunningForTest(_ pid: Int32) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/kill")
        process.arguments = ["-0", "\(pid)"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func expectRoute(_ route: CodexAutomationRoute?) throws -> CodexAutomationRoute {
        guard let route else {
            throw TestFailure(description: "Expected automation route")
        }
        return route
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

private final class StringCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String] = []

    func append(_ value: String) {
        lock.lock()
        values.append(value)
        lock.unlock()
    }

    func snapshot() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return values
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

private actor CapturingCodexBackend: CodexBackend {
    private var request: PromptRequest?
    private let response: String

    init(response: String) {
        self.response = response
    }

    func requestSnapshot() -> PromptRequest? { request }

    func invoke(_ request: PromptRequest, sessionId: String?, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse {
        self.request = request
        onEvent?(.sessionStarted("thread-smoke"))
        onEvent?(.turnStarted("turn-smoke"))
        let marker = request.promptText.components(separatedBy: " ").first { $0.hasPrefix("CODEX_BRIDGE_SMOKE_") } ?? "CODEX_BRIDGE_SMOKE_UNKNOWN"
        return CodexResponse(
            text: "\(marker) SUCCESS \(response)",
            sessionId: "thread-smoke",
            stdout: "",
            stderr: "",
            args: [],
            outputPath: ""
        )
    }
}

private final class ResponderCodexBackend: CodexBackend, @unchecked Sendable {
    private let responder: CodexInteractiveCallbackResponder?

    init(responder: CodexInteractiveCallbackResponder?) {
        self.responder = responder
    }

    func invoke(_ request: PromptRequest, sessionId: String?, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse {
        guard let responder else {
            throw TestFailure(description: "Expected interactive callback responder")
        }
        onEvent?(.sessionStarted("thread-callback"))
        onEvent?(.turnStarted("turn-callback"))
        let reply = try responder(
            "item/tool/requestUserInput",
            80,
            [
                "questions": [
                    [
                        "id": "choice",
                        "header": "Test",
                        "question": "Choose a test answer"
                    ]
                ]
            ]
        )
        let result = reply["result"] as? [String: Any]
        let answers = result?["answers"] as? [String: Any]
        let choice = answers?["choice"] as? [String: Any]
        let values = choice?["answers"] as? [String]
        let answer = values?.first ?? ""
        return CodexResponse(
            text: "Callback completed with \(answer).",
            sessionId: "thread-callback",
            stdout: "",
            stderr: "",
            args: [],
            outputPath: "/tmp/callback-output.txt"
        )
    }
}

private final class QueueMessageSource: MessageSource {
    private var messages: [MessageItem]

    init(messages: [MessageItem]) {
        self.messages = messages
    }

    func append(_ message: MessageItem) {
        messages.append(message)
    }

    func initializeCursor(state: inout BridgeState) async throws {}

    func fetchNewMessages(afterRowId: Int64) async throws -> [MessageItem] {
        let result = messages.filter { $0.rowId > afterRowId }
        messages.removeAll()
        return result
    }
}

private final class PersistentMessageSource: MessageSource {
    private var messages: [MessageItem]

    init(messages: [MessageItem]) {
        self.messages = messages
    }

    func initializeCursor(state: inout BridgeState) async throws {}

    func fetchNewMessages(afterRowId: Int64) async throws -> [MessageItem] {
        messages.filter { $0.rowId > afterRowId }
    }
}

private final class CapturingReplySink: ReplySink, @unchecked Sendable {
    struct Reply: Equatable {
        var recipient: String
        var service: String
        var text: String
    }
    struct Attachment: Equatable {
        var recipient: String
        var service: String
        var filePath: String
    }

    private let collector = ReplyCollector()

    func repliesSnapshot() async -> [Reply] {
        await collector.snapshot()
    }
    func attachmentsSnapshot() async -> [Attachment] {
        await collector.attachmentsSnapshot()
    }

    func sendReply(recipient: String, service: String, text: String) async throws -> OutboundDeliveryEvidence {
        await collector.append(Reply(recipient: recipient, service: service, text: text))
        return OutboundDeliveryEvidence(transport: "test", detail: "captured text reply")
    }

    func sendAttachment(recipient: String, service: String, filePath: String) async throws -> OutboundDeliveryEvidence {
        await collector.append(Attachment(recipient: recipient, service: service, filePath: filePath))
        return OutboundDeliveryEvidence(transport: "test", dbRowId: 123, detail: "captured attachment")
    }
}

private actor ReplyCollector {
    private var replies: [CapturingReplySink.Reply] = []
    private var attachments: [CapturingReplySink.Attachment] = []

    func append(_ reply: CapturingReplySink.Reply) {
        replies.append(reply)
    }
    func append(_ attachment: CapturingReplySink.Attachment) {
        attachments.append(attachment)
    }

    func snapshot() -> [CapturingReplySink.Reply] {
        replies
    }
    func attachmentsSnapshot() -> [CapturingReplySink.Attachment] {
        attachments
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
            "MESSAGES_LLM_BRIDGE_LAUNCH_AGENTS_DIR": launchAgents.path,
            "CODEX_HOME": root.appendingPathComponent(".codex").path
        ]
    )
}

private func makeSmokeMessagesDb(paths: RuntimePaths) throws -> URL {
    try FileManager.default.createDirectory(at: paths.tmpDir, withIntermediateDirectories: true)
    let db = paths.tmpDir.appendingPathComponent("chat.db")
    try runSQLite(db, """
    CREATE TABLE message (
      ROWID INTEGER PRIMARY KEY,
      guid TEXT,
      text TEXT,
      attributedBody BLOB,
      is_from_me INTEGER,
      error INTEGER,
      date_delivered INTEGER,
      date INTEGER,
      service TEXT,
      handle_id INTEGER
    );
    CREATE TABLE handle (
      ROWID INTEGER PRIMARY KEY,
      id TEXT,
      service TEXT
    );
    CREATE TABLE attachment (
      ROWID INTEGER PRIMARY KEY,
      transfer_name TEXT,
      filename TEXT,
      mime_type TEXT,
      uti TEXT,
      transfer_state INTEGER
    );
    CREATE TABLE message_attachment_join (
      message_id INTEGER,
      attachment_id INTEGER
    );
    """)
    return db
}

private func runSQLite(_ db: URL, _ sql: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
    process.arguments = [db.path, sql]
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        throw TestFailure(description: "sqlite3 failed with status \(process.terminationStatus)")
    }
}

private func shellQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

private func waitForReplies(_ sink: CapturingReplySink, count: Int, timeout: TimeInterval = 5) async throws -> [CapturingReplySink.Reply] {
    let deadline = Date().addingTimeInterval(timeout)
    var replies = await sink.repliesSnapshot()
    while replies.count < count, Date() < deadline {
        try await Task.sleep(nanoseconds: 50_000_000)
        replies = await sink.repliesSnapshot()
    }
    guard replies.count >= count else {
        throw TestFailure(description: "Timed out waiting for \(count) replies; saw \(replies.count)")
    }
    return replies
}

private func waitForState(_ stores: RuntimeStores, timeout: TimeInterval = 5, condition: (BridgeState) -> Bool) async throws -> BridgeState {
    let deadline = Date().addingTimeInterval(timeout)
    var latest = try stores.state.load()
    while !condition(latest), Date() < deadline {
        try await Task.sleep(nanoseconds: 50_000_000)
        latest = try stores.state.load()
    }
    guard condition(latest) else {
        throw TestFailure(description: "Timed out waiting for bridge state condition")
    }
    return latest
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

private func writeAutomationSessionFixture(paths: RuntimePaths) throws {
    let dir = paths.codexSessionsDir.appendingPathComponent("2026/05/13")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let file = dir.appendingPathComponent("rollout-2026-05-13T07-01-03-019e20ff-4dca-7571-9425-0713bddb0d73.jsonl")
    let data = Data("""
    {"timestamp":"2026-05-13T11:01:03.218Z","type":"session_meta","payload":{"id":"019e20ff-4dca-7571-9425-0713bddb0d73","cwd":"/Users/moss/Developer/Codex Misc"}}
    {"timestamp":"2026-05-13T11:01:07.737Z","type":"event_msg","payload":{"type":"user_message","message":"Automation: Morning News and Weather Digest\\nAutomation ID: morning-news-and-weather-digest\\nAutomation memory: $CODEX_HOME/automations/morning-news-and-weather-digest/memory.md"}}
    {"timestamp":"2026-05-13T11:05:16.869Z","type":"event_msg","payload":{"type":"task_complete","last_agent_message":"Morning Digest\\nBring an umbrella.\\n::inbox-item{title=\\"Morning digest\\" summary=\\"Review highlights\\"}"}}

    """.utf8)
    try data.write(to: file, options: .atomic)
}

private func writeCapabilityCacheWithInventory(paths: RuntimePaths) throws {
    try FileManager.default.createDirectory(at: paths.stateDir, withIntermediateDirectories: true)
    let entry = CodexCapabilityCacheEntryForTest(
        cachedAt: "2026-05-09T00:00:00.000Z",
        capabilities: CodexCapabilities(
            version: "0.130.0",
            appServerAvailable: true,
            remoteControlAvailable: true,
            threadReadAvailable: true,
            inventory: CodexToolInventory(
                skills: [CodexSkillInventoryItem(name: "chrome:Chrome", enabled: true)],
                plugins: [CodexPluginInventoryItem(name: "openai-bundled", displayName: "OpenAI Bundled")],
                apps: [CodexAppInventoryItem(id: "browser", name: "Browser", isAccessible: true, isEnabled: true)],
                mcpServers: [CodexMcpServerInventoryItem(name: "node_repl", toolCount: 1)]
            ),
            warnings: []
        )
    )
    let data = try JSONEncoder().encode(entry)
    try data.write(to: paths.stateDir.appendingPathComponent("codex-capabilities.json"), options: .atomic)
}

private struct CodexCapabilityCacheEntryForTest: Codable {
    var cachedAt: String
    var capabilities: CodexCapabilities
}
