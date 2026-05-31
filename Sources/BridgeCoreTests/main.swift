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
        try testBridgeInstructionsAreTransportOnly()
        try testAutomationRequestsStayPlainPromptText()
        try testPromptBatchPreservesPluginIntentAndOrder()
        try await testRecentMissingAttachmentDefersCursorUntilFileExists()
        try testStreamPublishInvocationUsesAbsoluteNPMAndPathParent()
        try testStreamPublishCrosspostSummaryFormatsAllTargetsOK()
        try testStreamPublishCrosspostSummaryFormatsFailedTarget()
        try testStreamPublishCrosspostSummaryFormatsSkippedTarget()
        try await testStreamPublishMarkerRunsWebsiteWrapperAndRepliesWithResult()
        try await testStreamPublishReplyIncludesCrosspostSummaryAfterCommit()
        try await testStreamPublishDuplicateGuidDoesNotRepublish()
        try await testStreamPublishJobsRunSingleFlight()
        try await testStreamPublishFailureRepliesAndMarksLedgerFailed()
        try await testStreamPublishNPMResolutionFailureRepliesAndMarksLedgerFailed()
        try await testStreamPublishWaitsForStableMediaAndIncludesIt()
        try await testStreamPublishUnsupportedMediaFailsWithoutWrapper()
        try await testDoubleFerrisWaitsForNextTrustedMediaAndPublishesCombinedEvent()
        try await testDoubleFerrisTimesOutWaitingForMedia()
        try await testDoubleFerrisUnsupportedNextMediaFailsWithoutWrapper()
        try await testSQLiteMessageSourceAttachmentRowsAndClassification()
        try await testSQLiteMessageSourceReadsAttributedBodyOnlyText()
        try testPreviousImageReferenceAddsRecentImage()
        try testPreviousImageReferenceSkipsUnsupportedRecentImage()
        try testLiveSmokeResultsStatusHighlightsLatestBlocker()
        try testLiveSmokeResultsKeepLatestPerSmokeName()
        try testRecordLiveSmokeResultPersistsToState()
        try await testMissingPreviousImageReferenceAsksForSource()
        try await testCodexSmokeAttachmentCommandSendsProbeAndSummary()
        try await testCodexSmokeBridgeAttachCommandUsesDirectiveHandoff()
        try await testCodexSmokeGeneratedImageStartsAppServerAndAttachesResult()
        try await testCodexSmokeEditImageCheckUsesPreviousImageAndAttachesResult()
        try await testPreviousImageFollowUpConvertsUnsupportedLatestImage()
        try await testCodexSmokeAppServerCommandRunsFinalAnswerProbe()
        try await testCodexSmokeCapabilityCommandRunsAppServerProbe()
        try await testCodexGatesCommandRepliesWithChecklist()
        try await testCodexTrustedGatesCommandRepliesWithEvidence()
        try testTrustedGateRunbookListsExactMessagesAndFollowUps()
        try await testCodexSmokeCallbackCapturesNextReplyAndClearsState()
        try await testCodexSmokeAppServerCallbackStartsDefaultBackendTurn()
        try await testCodexSmokeMcpElicitationCallbackStartsDefaultBackendTurn()
        try testInboundImageSmokeBuildsLocalImageRequest()
        try testOutboundImageSmokeBuildsLocalImageRequest()
        try testImageEditSmokeBuildsPreviousImageRequest()
        try testAppServerCallbackSmokeResponseShapes()
        try testInboundImageSmokeRequiresTrustedInboundImage()
        try await testInboundImageSmokeRecoversLatestTrustedImageFromMessagesDb()
        try await testCodexSmokeOutboundImageCheckSendsProbeAndBuildsFollowUp()
        try testDiagnosticMentionOfDailyBriefingDoesNotCreateAutomation()
        try testAutomationCreationClassifierMatrix()
        try testCodexAutomationCreationWritesAppAutomationToml()
        try testCodexAutomationSmokeCreatesRouteAndStatus()
        try testActiveBridgeSmokeAutomationDiagnostics()
        try await testCodexAutomationsReportsCreationInProgress()
        try await testCodexAutomationsReportsConfirmedCreationEvidence()
        try testBridgeStateSavePreservesConcurrentAutomationFields()
        try testBridgeStateSaveMergesSameActiveJobDetails()
        try testBridgeStateUpdateSerializesSeparateStoreInstances()
        try testBridgeStateBoxSerializesConcurrentMutations()
        try testBridgeServiceSessionAndJobStartMutationsUseStateOwner()
        try testBridgeServiceAutomationMutationsUseStateOwner()
        try testBridgeServiceBatchAndCallbackMutationsUseStateOwner()
        try testBridgeJobQueuePrioritizesCutThroughJobs()
        try testBridgeServiceUsesJobQueueOwner()
        try testComputerUseProbeDetailIncludesWindowDiagnostics()
        try testBridgeSmokePNGFixtureHasValidChunkCRCs()
        try testCapabilityFormattingAndCacheSnapshot()
        try await testCapabilityBestEffortPrefersCache()
        try await testOutboundSmokeTextEvidenceFindsMarkerInMessagesDb()
        try await testOutboundSmokeAttachmentEvidenceFindsMarkerInTransferName()
        try await testOutboundSmokeAttachmentEvidenceFallsBackToLatestAttachment()
        try await testTrustedGateEvidenceFindsInboundCommandAndOutboundReply()
        try await testTrustedGateEvidenceTracksCallbackFollowUp()
        try await testClipboardAttachmentSendRetriesWhenNoDbRowAppears()
        try await testAttachmentSendWaitsForDelayedMessagesDbRow()
        try await testSmsAttachmentSendUsesSmsServiceAndReportsFailedRow()
        try await testRecentFailedOutboundEvidenceFindsFailedTextAndAttachmentRows()
        try testCodexAppServerProcessSnapshotParsesTransportsAndOrphans()
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
        try await testAppServerBackendKeepsDeveloperInstructionsTransportOnly()
        try await testAppServerBackendDeveloperInstructionsPreventSelfRestart()
        try await testAppServerBackendDoesNotAddStructuredMentionsToTurnInput()
        try await testAppServerBackendUsesDefaultSandboxForAutomationRequests()
        try await testAppServerBackendRejectsNonFinalAgentMessageAsReply()
        try await testAppServerBackendForwardsDynamicToolRequests()
        try await testAppServerBackendReturnsDynamicToolFailureWhenMcpCallStalls()
        try await testAppServerBackendRejectsUnsupportedDynamicToolNamespace()
        try await testAppServerBackendHandlesMalformedDynamicToolRequest()
        try await testAppServerBackendNormalizesOddDynamicToolResponses()
        try await testAppServerBackendResolvesInteractiveCallbacksWithResponder()
        try await testAppServerBackendBlocksUserInputAndElicitationRequests()
        try await testAppServerBackendDeniesApprovalRequestsWithoutHanging()
        try await testAppServerBackendFailsUnsupportedServerRequestsVisibly()
        try await testBridgeDefaultBackendInteractiveCallbackEndToEnd()
        try await testAppServerBackendNamesNewThreadFromPrompt()
        try await testAppServerBackendResumesThreadAndIgnoresMalformedNotifications()
        try await testAppServerBackendErrorNotificationThrowsBridgeFailure()
        try testCodexProgressSummaryHandlesAppServerNotifications()
        try testCodexProgressSummaryUsesCommentaryText()
        try testOutgoingAttachmentIntentGate()
        try await testBridgeAttachDirectiveAlwaysSendsValidatedAttachment()
        try await testBridgeAttachDirectiveDoesNotSendSuccessTextWhenAttachmentFails()
        try await testProgressEventsUpdateStateWithoutSendingSms()
        try await testProgressEventsSendVisibleUpdatesAfterInterval()
        try await testDeadActiveJobOnStartupNotifiesAndClears()
        try await testBridgeRepairDryRunReportsStaleJobAndMissedAttributedRows()
        try await testBridgeRepairStagesRecoverableAndMissedRowsForReplay()
        try await testBridgeRepairNoReplayReportsAndAdvancesPastMissedRows()
        try await testTryAgainReplaysRecoveredActiveJobBatch()
        try await testPendingInteractiveCallbackCapturesNextReply()
        try await testPendingInteractiveCallbackCancelAndTimeout()
        try testCorruptedStateJsonBacksUpAndDefaults()
        try testStateRecoveryBackupDiagnosticsReportBackupPath()
        try testLaunchAgentProgramDiagnostics()
        try testLaunchAgentLoadStateFormatting()
        try testRuntimeExecutableIdentityDiagnostics()
        try testBridgeGateChecklistEnumeratesLocalAndTrustedGates()
        try testBridgeGateStrictReportFailsOnTrustedAndLiveBlockers()
        try testBridgeGateStrictReportAcceptsCapabilityBlockersWithEvidence()
        try await testAutomationRequestStartsNormalCodexJob()
        try await testCodexAutomationsReportsCreationInProgress()
        try await testNormalTickDoesNotForwardCompletedAutomationSessions()
        try await testAutomationForwardOnceSidecar()
        try testCompletedAutomationScanUsesDeliveredSessionLowerBound()
        try testTerminateProcessTreeIncludesRoot()
        try await testOrdinaryTextDuringActiveJobQueuesNextBatchWhileCodexStatusCutsThrough()
        print("BridgeCoreTests passed.")
    }

    private static func testExactCodexCommandsBypassNormalPromptBatching() throws {
        try expect(bridgeLocalCommandName("/codex status") == "/codex", "exact codex status command")
        try expect(bridgeLocalCommandName("/codex status verbose") == "/codex", "exact codex verbose status command")
        try expect(bridgeLocalCommandName("  /codex open  ") == "/codex", "exact codex open command")
        try expect(bridgeLocalCommandName("/codex history") == "/codex", "exact codex history command")
        try expect(bridgeLocalCommandName("/codex automations") == "/codex", "exact codex automations command")
        try expect(bridgeLocalCommandName("/codex gates") == "/codex", "exact codex gates command")
        try expect(bridgeLocalCommandName("/codex gates verbose") == "/codex", "exact codex verbose gates command")
        try expect(bridgeLocalCommandName("/codex trusted-gates") == "/codex", "exact codex trusted-gates command")
        try expect(bridgeLocalCommandName("/codex trusted-gates runbook") == "/codex", "exact codex trusted-gates runbook command")
        try expect(bridgeLocalCommandName("/codex retry-last-send") == "/codex", "exact codex retry command")
        try expect(bridgeLocalCommandName("/codex smoke text") == "/codex", "codex text smoke command")
        try expect(bridgeLocalCommandName("/codex smoke attachment") == "/codex", "codex attachment smoke command")
        try expect(bridgeLocalCommandName("/codex smoke bridge-attach") == "/codex", "codex bridge-attach smoke command")
        try expect(bridgeLocalCommandName("/codex smoke generated-image") == "/codex", "codex generated-image smoke command")
        try expect(bridgeLocalCommandName("/codex smoke edit-image-check") == "/codex", "codex edit image smoke command")
        try expect(bridgeLocalCommandName("/codex smoke browser") == "/codex", "codex browser smoke command")
        try expect(bridgeLocalCommandName("/codex smoke chrome") == "/codex", "codex chrome smoke command")
        try expect(bridgeLocalCommandName("/codex smoke computer-use") == "/codex", "codex computer-use smoke command")
        try expect(bridgeLocalCommandName("/codex smoke automation") == "/codex", "codex automation smoke command")
        try expect(bridgeLocalCommandName("/codex smoke callback") == "/codex", "codex callback smoke command")
        try expect(bridgeLocalCommandName("/codex smoke app-server-callback") == "/codex", "codex app-server callback smoke command")
        try expect(bridgeLocalCommandName("/codex smoke mcp-elicitation-callback") == "/codex", "codex MCP elicitation callback smoke command")
        try expect(bridgeLocalCommandName("/codex smoke app-server") == "/codex", "codex app-server smoke command")
        try expect(bridgeLocalCommandName("/codex smoke inbound-image-check") == "/codex", "codex inbound image smoke command")
        try expect(bridgeLocalCommandName("/codex smoke outbound-image-check") == "/codex", "codex outbound image smoke command")
        try expect(bridgeLocalCommandName("/codex smoke unknown") == nil, "unsupported codex smoke command is prompt text")
        try expect(bridgeLocalCommandName("/codex status please") == nil, "non-exact codex command is prompt text")
        try expect(bridgeLocalCommandName("what does /codex status show?") == nil, "natural language codex mention is prompt text")
        try expect(bridgeLocalCommandName("/status please") == "/status", "existing command arguments still work")
    }

    private static func testBridgeInstructionsAreTransportOnly() throws {
        let instructions = BridgeConstants.baseBridgeInstructions
        try expect(instructions.contains("Return plain text only"), "bridge instructions preserve Messages-safe plain text contract")
        try expect(instructions.contains("BRIDGE_ATTACH:"), "bridge instructions preserve attachment handoff contract")
        try expect(!instructions.contains("remote control surface for Codex running on this Mac"), "bridge instructions do not describe a capability steering surface")
        try expect(!instructions.contains("use Codex automation tools"), "bridge instructions do not route automation requests")
        try expect(!instructions.contains("name plugins, skills, apps, or tools"), "bridge instructions do not route plugin and skill requests")
        try expect(!instructions.contains("Do not modify the Messages bridge itself unless the user explicitly asks"), "bridge instructions avoid bridge-specific source-code steering")
    }

    private static func testAutomationRequestsStayPlainPromptText() throws {
        let batch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-12T00:00:00.000Z",
            deadlineAt: "2026-05-12T00:00:01.000Z",
            items: [
                MessageItem(rowId: 1, guid: "guarded", text: "Create an automation that sends me a daily digest every morning.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-12T00:00:00.000Z", attachments: [])
            ]
        )
        let request = buildPromptRequest(from: batch)
        try expect(request.promptText.contains("Create an automation that sends me a daily digest every morning."), "automation request text is preserved")
        try expect(!request.promptText.contains("Bridge routing guard:"), "automation prompt does not get bridge routing guard")
        try expect(!request.promptText.contains("Do not implement, modify, inspect, or continue any Messages bridge scheduler"), "automation prompt does not get scheduler guard text")
        try expect(!request.promptText.contains("If a Codex automation tool is available, use it"), "automation prompt does not get tool-routing text")
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
        try expect(request.promptText.contains("@Chrome"), "capability intent remains plain prompt text")
    }

    private static func testRecentMissingAttachmentDefersCursorUntilFileExists() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.activeJobAckEnabled = false
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

    private static func testStreamPublishInvocationUsesAbsoluteNPMAndPathParent() throws {
        let npmPath = "/Users/moss/.nvm/versions/node/v25.8.2/bin/npm"
        let invocation = streamPublishInvocation(eventJsonPath: "/tmp/event.json", resultJsonPath: "/tmp/result.json", npmPath: npmPath)

        try expect(invocation.cwd == "/Users/moss/Developer/urcad.es", "stream publish wrapper cwd is website repo")
        try expect(invocation.executable == "/usr/bin/env", "stream publish wrapper uses env executable")
        try expect(invocation.arguments == [
            "PATH=/Users/moss/.nvm/versions/node/v25.8.2/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            npmPath, "run", "publish:stream:run", "--",
            "--event", "/tmp/event.json",
            "--result-json", "/tmp/result.json"
        ], "stream publish invocation uses absolute npm and PATH with npm parent first")
    }

    private static func testStreamPublishCrosspostSummaryFormatsAllTargetsOK() throws {
        let summary = try parseStreamPublishResultForTest("""
        {
          "ok": true,
          "phase": "complete",
          "publicUrl": "https://urcad.es/writing/all-ok",
          "commit": "abcdef1234567890",
          "crossposts": {
            "attempted": true,
            "bluesky": { "ok": true, "skipped": false, "error": null },
            "arena": { "ok": true, "skipped": false, "error": null },
            "gotosocial": { "ok": true, "skipped": false, "error": null }
          }
        }
        """)

        try expect(summary.crosspostSummary == "Cross-posts: Bluesky ok, Are.na ok, GoToSocial ok", "all-ok crossposts are summarized compactly")
    }

    private static func testStreamPublishCrosspostSummaryFormatsFailedTarget() throws {
        let summary = try parseStreamPublishResultForTest("""
        {
          "ok": true,
          "phase": "complete",
          "publicUrl": "https://urcad.es/writing/one-failed",
          "commit": "abcdef1234567890",
          "crossposts": {
            "attempted": true,
            "bluesky": { "ok": true, "skipped": false, "error": null },
            "arena": { "ok": true, "skipped": false, "error": null },
            "gotosocial": { "ok": false, "skipped": false, "error": "status 401: unauthorized" }
          }
        }
        """)

        try expect(summary.crosspostSummary == "Cross-posts: Bluesky ok, Are.na ok, GoToSocial failed (401)", "failed crosspost includes status code without raw error text")
    }

    private static func testStreamPublishCrosspostSummaryFormatsSkippedTarget() throws {
        let summary = try parseStreamPublishResultForTest("""
        {
          "ok": true,
          "phase": "complete",
          "publicUrl": "https://urcad.es/writing/skipped",
          "commit": "abcdef1234567890",
          "crossposts": {
            "attempted": true,
            "bluesky": { "ok": false, "skipped": true, "error": "not configured" },
            "arena": { "ok": true, "skipped": false, "error": null },
            "gotosocial": { "ok": true, "skipped": false, "error": null }
          }
        }
        """)

        try expect(summary.crosspostSummary == "Cross-posts: Bluesky skipped, Are.na ok, GoToSocial ok", "skipped crosspost target is summarized without raw reason")
    }

    private static func testStreamPublishMarkerRunsWebsiteWrapperAndRepliesWithResult() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.activeJobAckEnabled = false
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 10, guid: "imsg-guid/with space", text: "🎡 battery 1%", handleId: "+15551234567", service: "iMessage", receivedAt: "2026-05-30T12:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "should not run")
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://urcad.es/writing/battery-1", commitHash: "abcdef1234567890"))
        let npmPath = "/Users/moss/.nvm/versions/node/v25.8.2/bin/npm"
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in backend },
            streamPublisher: publisher.run,
            resolveStreamPublisherNPM: { .success(npmPath) }
        )

        try await service.initialize()
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        try expect(invocations.count == 1, "stream publish marker invokes website wrapper once")
        let invocation = try unwrap(invocations.first, "missing stream publisher invocation")
        try expect(invocation.cwd == "/Users/moss/Developer/urcad.es", "stream publish wrapper cwd is website repo")
        try expect(invocation.executable == "/usr/bin/env", "stream publish wrapper uses env executable")
        try expect(invocation.arguments == [
            "PATH=/Users/moss/.nvm/versions/node/v25.8.2/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            npmPath, "run", "publish:stream:run", "--",
            "--event", invocation.eventJsonPath,
            "--result-json", invocation.resultJsonPath
        ], "stream publish wrapper args use absolute npm and exact wrapper arguments")
        try expect(invocation.eventJsonPath.hasPrefix(paths.tmpDir.appendingPathComponent("stream-events").path), "event JSON is under bridge tmp stream-events")
        try expect(invocation.resultJsonPath.hasPrefix(paths.tmpDir.appendingPathComponent("stream-events").path), "result JSON is under bridge tmp stream-events")
        try expect(URL(fileURLWithPath: invocation.eventJsonPath).lastPathComponent.hasSuffix(".json"), "event JSON has json extension")
        try expect(!URL(fileURLWithPath: invocation.eventJsonPath).lastPathComponent.hasSuffix(".event.json"), "event JSON path uses the bridge contract filename shape")
        try expect(!invocation.eventJsonPath.hasPrefix("/Users/moss/Developer/urcad.es"), "event JSON is outside website repo")
        try expect(!invocation.resultJsonPath.hasPrefix("/Users/moss/Developer/urcad.es"), "result JSON is outside website repo")

        let event = try readJsonObject(invocation.eventJsonPath)
        try expect(event["id"] as? String == "imsg-guid/with space", "event id preserves message guid")
        try expect(event["source"] as? String == "imessage", "event source is imessage")
        try expect(event["sender"] as? String == "+15551234567", "event sender preserves trusted sender")
        try expect(event["receivedAt"] as? String == "2026-05-30T12:00:00.000Z", "event receivedAt is message timestamp")
        try expect(event["text"] as? String == "🎡 battery 1%", "event text preserves raw marker")
        try expect((event["media"] as? [[String: Any]])?.isEmpty == true, "text-only stream event has empty media")

        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text).contains("Published: https://urcad.es/writing/battery-1\nCommit: abcdef1"), "success reply includes URL and short commit")
        try expect(replies.map(\.text).contains { !$0.contains("Cross-posts:") }, "missing crossposts preserves current success reply")
        let request = await backend.requestSnapshot()
        try expect(request == nil, "stream publish message does not enter normal Codex prompt queue")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["imsg-guid/with space"], "missing stream publish ledger record")
        try expect(record.status == "succeeded", "stream publish ledger is succeeded")
        try expect(record.publicUrl == "https://urcad.es/writing/battery-1", "stream publish ledger records public URL")
        try expect(record.commitHash == "abcdef1234567890", "stream publish ledger records commit hash")
    }

    private static func testStreamPublishReplyIncludesCrosspostSummaryAfterCommit() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 15, guid: "crosspost-guid", text: "🎡 crosspost me", handleId: "+1", service: "iMessage", receivedAt: "2026-05-31T12:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let crossposts = """
        {
          "attempted": true,
          "bluesky": { "ok": true, "skipped": false, "error": null },
          "arena": { "ok": true, "skipped": false, "error": null },
          "gotosocial": { "ok": true, "skipped": false, "error": null }
        }
        """
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://urcad.es/writing/crosspost", commitHash: "123456789abcdef", crosspostsJson: crossposts))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text).contains("Published: https://urcad.es/writing/crosspost\nCommit: 1234567\nCross-posts: Bluesky ok, Are.na ok, GoToSocial ok"), "success reply appends crosspost summary after commit")
    }

    private static func testStreamPublishDuplicateGuidDoesNotRepublish() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        var state = defaultBridgeState()
        state.streamPublishLedger = [
            "dup-guid": StreamPublishRecord(
                rowId: 7,
                guid: "dup-guid",
                receivedAt: "2026-05-30T12:00:00.000Z",
                rawTextHash: "hash",
                attachmentIds: [],
                eventJsonPath: "/tmp/event.json",
                resultJsonPath: "/tmp/result.json",
                status: "succeeded",
                startedAt: "2026-05-30T12:00:00.000Z",
                finishedAt: "2026-05-30T12:01:00.000Z",
                exitCode: 0,
                stdoutTail: nil,
                stderrTail: nil,
                publicUrl: "https://urcad.es/writing/already",
                commitHash: "abcdef1",
                failureReason: nil
            )
        ]
        try stores.state.save(state)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 8, guid: "dup-guid", text: "🎡 duplicate", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:02:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://example.invalid/new", commitHash: "1111111"))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        let savedState = try stores.state.load()
        try expect(invocations.isEmpty, "duplicate stream publish guid does not invoke wrapper")
        try expect(savedState.lastProcessedRowId == 8, "duplicate stream publish still advances cursor")
    }

    private static func testStreamPublishJobsRunSingleFlight() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "single-1", text: "🎡 first", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:00:00.000Z", attachments: []),
            MessageItem(rowId: 2, guid: "single-2", text: "🎡 second", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:00:01.000Z", attachments: [])
        ])
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://urcad.es/writing/single", commitHash: "2222222"), delayNanoseconds: 100_000_000)
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in CapturingReplySink() }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let maxConcurrent = await publisher.maxConcurrentSnapshot()
        let invocationCount = await publisher.invocationsSnapshot().count
        try expect(maxConcurrent == 1, "stream publish wrapper runs single-flight")
        try expect(invocationCount == 2, "both stream publish jobs run sequentially")
    }

    private static func testStreamPublishFailureRepliesAndMarksLedgerFailed() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 11, guid: "fail-guid", text: "🎡 fail me", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let publisher = CapturingStreamPublisher(mode: .failure(phase: "deploy", error: "CF_API_TOKEN=super-secret-token failed", stderr: "Authorization: Bearer secret-value"))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let replies = await sink.repliesSnapshot()
        try expect(replies.last?.text.contains("Publish failed during deploy:") == true, "failure reply includes failing phase")
        try expect(replies.last?.text.contains("super-secret-token") == false, "failure reply redacts token values")
        try expect(replies.last?.text.contains("secret-value") == false, "failure reply redacts bearer token values")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["fail-guid"], "missing failed stream publish record")
        try expect(record.status == "failed", "failed stream publish updates ledger status")
        try expect(record.exitCode == 1, "failed stream publish records exit code")
        try expect(record.failureReason?.contains("deploy") == true, "failed stream publish records phase")
    }

    private static func testStreamPublishNPMResolutionFailureRepliesAndMarksLedgerFailed() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 14, guid: "npm-missing-guid", text: "🎡 missing npm", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://example.invalid/should-not-run", commitHash: "5555555"))
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in CapturingCodexBackend(response: "unused") },
            streamPublisher: publisher.run,
            resolveStreamPublisherNPM: { .failure("npm not found from /bin/zsh -lc 'command -v npm'") }
        )

        try await service.initialize()
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        let replies = await sink.repliesSnapshot()
        try expect(invocations.isEmpty, "missing npm does not invoke wrapper")
        try expect(replies.last?.text.contains("Publish failed during wrapper:") == true, "missing npm replies with wrapper phase")
        try expect(replies.last?.text.contains("npm not found") == true, "missing npm reply is clear")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["npm-missing-guid"], "missing npm failure ledger record")
        try expect(record.status == "failed", "missing npm marks ledger failed")
        try expect(record.failureReason?.contains("wrapper") == true, "missing npm records wrapper failure phase")
        try expect(record.failureReason?.contains("npm not found") == true, "missing npm records clear failure reason")
    }

    private static func testStreamPublishWaitsForStableMediaAndIncludesIt() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let image = paths.tmpDir.appendingPathComponent("photo.jpg")
        try Data("image bytes".utf8).write(to: image)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 12, guid: "media-guid", text: "🎡 image post", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:00:00.000Z", attachments: [
                AttachmentRef(attachmentId: 44, transferName: "photo.jpg", mimeType: "image/jpeg", uti: nil, absolutePath: image.path, kind: "image", exists: true)
            ])
        ])
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://urcad.es/writing/media", commitHash: "3333333"))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in CapturingReplySink() }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        let invocation = try unwrap(invocations.first, "missing media stream invocation")
        let event = try readJsonObject(invocation.eventJsonPath)
        let media = try unwrap(event["media"] as? [[String: Any]], "missing media array")
        let firstMedia = try unwrap(media.first, "missing first media item")
        try expect(media.count == 1, "stream event includes ready media")
        try expect(firstMedia["path"] as? String == image.path, "stream media path is absolute")
        try expect(firstMedia["mimeType"] as? String == "image/jpeg", "stream media preserves mime type")
        try expect(firstMedia["alt"] as? String == "", "stream media alt defaults empty")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["media-guid"], "missing media ledger record")
        try expect(record.status == "succeeded", "media stream publish succeeds after readiness")
    }

    private static func testStreamPublishUnsupportedMediaFailsWithoutWrapper() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let pdf = paths.tmpDir.appendingPathComponent("paper.pdf")
        try Data("%PDF".utf8).write(to: pdf)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 13, guid: "unsupported-guid", text: "🎡 pdf post", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T12:00:00.000Z", attachments: [
                AttachmentRef(attachmentId: 45, transferName: "paper.pdf", mimeType: "application/pdf", uti: nil, absolutePath: pdf.path, kind: "pdf", exists: true)
            ])
        ])
        let sink = CapturingReplySink()
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://example.invalid/should-not-run", commitHash: "4444444"))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        let replies = await sink.repliesSnapshot()
        try expect(invocations.isEmpty, "unsupported media does not invoke wrapper")
        try expect(replies.last?.text.contains("Publish failed during media:") == true, "unsupported media failure replies")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["unsupported-guid"], "missing unsupported media ledger record")
        try expect(record.status == "failed", "unsupported media marks ledger failed")
        try expect(record.failureReason?.contains("Unsupported attachment") == true, "unsupported media records clear failure")
    }

    private static func testDoubleFerrisWaitsForNextTrustedMediaAndPublishesCombinedEvent() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let image = paths.tmpDir.appendingPathComponent("physical-memory.jpg")
        try Data("image bytes".utf8).write(to: image)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 20, guid: "text-guid", text: "🎡🎡 physical memory", handleId: "+15551234567", service: "iMessage", receivedAt: "2026-05-30T21:39:00.000Z", attachments: []),
            MessageItem(rowId: 21, guid: "media-guid", text: "", handleId: "+15551234567", service: "iMessage", receivedAt: "2026-05-30T21:40:00.000Z", attachments: [
                AttachmentRef(attachmentId: 99, transferName: "physical-memory.jpg", mimeType: "image/jpeg", uti: nil, absolutePath: image.path, kind: "image", exists: true)
            ])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "should not run")
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://urcad.es/writing/260530/", commitHash: "9999999abcdef"))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in backend }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text).contains("Waiting for media for: physical memory"), "double ferris replies that it is waiting for media")
        try expect(replies.map(\.text).contains("Published: https://urcad.es/writing/260530/\nCommit: 9999999"), "double ferris success reply includes URL and short commit")
        let request = await backend.requestSnapshot()
        try expect(request == nil, "double ferris messages do not enter normal Codex prompt queue")
        let invocations = await publisher.invocationsSnapshot()
        try expect(invocations.count == 1, "double ferris invokes website wrapper once after media arrives")
        let invocation = try unwrap(invocations.first, "missing double ferris stream invocation")
        let event = try readJsonObject(invocation.eventJsonPath)
        try expect(event["id"] as? String == "text-guid+media-guid+99", "double ferris event id derives from text guid, media guid, and attachment id")
        try expect(event["source"] as? String == "imessage", "double ferris event source is imessage")
        try expect(event["sender"] as? String == "+15551234567", "double ferris event sender comes from original trusted sender")
        try expect(event["receivedAt"] as? String == "2026-05-30T21:39:00.000Z", "double ferris event receivedAt comes from original text")
        try expect(event["text"] as? String == "🎡🎡 physical memory", "double ferris event preserves original raw text")
        let media = try unwrap(event["media"] as? [[String: Any]], "missing double ferris media array")
        let firstMedia = try unwrap(media.first, "missing double ferris media item")
        try expect(media.count == 1, "double ferris event includes one media item")
        try expect(firstMedia["path"] as? String == image.path, "double ferris media path is absolute")
        try expect(firstMedia["mimeType"] as? String == "image/jpeg", "double ferris media preserves MIME type")
        try expect(firstMedia["alt"] as? String == "", "double ferris media alt defaults empty")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["text-guid"], "missing double ferris text ledger record")
        try expect(record.status == "succeeded", "double ferris ledger under text guid succeeds")
        try expect(record.attachmentIds == [99], "double ferris ledger records consumed attachment id")
        try expect(record.eventJsonPath == invocation.eventJsonPath, "double ferris ledger records combined event path")
    }

    private static func testDoubleFerrisTimesOutWaitingForMedia() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 30, guid: "timeout-text-guid", text: "🎡🎡 no media", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T22:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://example.invalid/should-not-run", commitHash: "0000000"))
        var currentDate = Date(timeIntervalSince1970: 100)
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") }, now: { currentDate })

        try await service.initialize()
        try await service.tick()
        currentDate = Date(timeIntervalSince1970: 701)
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        try expect(invocations.isEmpty, "double ferris timeout does not invoke wrapper")
        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text).contains("Waiting for media for: no media"), "double ferris timeout starts with waiting reply")
        try expect(replies.last?.text.contains("Timed out waiting for media for: no media") == true, "double ferris timeout replies clearly")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["timeout-text-guid"], "missing timed out double ferris ledger record")
        try expect(record.status == "failed", "double ferris timeout marks ledger failed")
        try expect(record.failureReason?.contains("Timed out waiting for media") == true, "double ferris timeout records clear failure")
    }

    private static func testDoubleFerrisUnsupportedNextMediaFailsWithoutWrapper() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        let pdf = paths.tmpDir.appendingPathComponent("physical-memory.pdf")
        try Data("%PDF".utf8).write(to: pdf)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 40, guid: "unsupported-text-guid", text: "🎡🎡 physical memory", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T23:00:00.000Z", attachments: []),
            MessageItem(rowId: 41, guid: "unsupported-media-guid", text: "", handleId: "+1", service: "iMessage", receivedAt: "2026-05-30T23:01:00.000Z", attachments: [
                AttachmentRef(attachmentId: 101, transferName: "physical-memory.pdf", mimeType: "application/pdf", uti: nil, absolutePath: pdf.path, kind: "pdf", exists: true)
            ])
        ])
        let sink = CapturingReplySink()
        let publisher = CapturingStreamPublisher(mode: .success(publicUrl: "https://example.invalid/should-not-run", commitHash: "0000000"))
        let service = BridgeService(paths: paths, stores: stores, makeSource: { _ in source }, makeReplySink: { _ in sink }, makeCodex: { _ in CapturingCodexBackend(response: "unused") }, streamPublisher: publisher.run, resolveStreamPublisherNPM: { .success("/Users/moss/.nvm/versions/node/v25.8.2/bin/npm") })

        try await service.initialize()
        try await service.tick()

        let invocations = await publisher.invocationsSnapshot()
        try expect(invocations.isEmpty, "double ferris unsupported media does not invoke wrapper")
        let replies = await sink.repliesSnapshot()
        try expect(replies.map(\.text).contains("Waiting for media for: physical memory"), "double ferris unsupported media starts with waiting reply")
        try expect(replies.last?.text.contains("Publish failed during media:") == true, "double ferris unsupported media replies clearly")
        try expect(replies.last?.text.contains("Unsupported attachment") == true, "double ferris unsupported media names unsupported attachment")
        let record = try unwrap(try stores.state.load().streamPublishLedger?["unsupported-text-guid"], "missing unsupported double ferris ledger record")
        try expect(record.status == "failed", "double ferris unsupported media marks ledger failed")
        try expect(record.attachmentIds == [101], "double ferris unsupported media records consumed attachment id")
        try expect(record.failureReason?.contains("Unsupported attachment") == true, "double ferris unsupported media records clear failure")
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

    private static func testSQLiteMessageSourceReadsAttributedBodyOnlyText() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        let attributed = attributedBodyFixture(text: "Hello?", extraStrings: ["streamtyped", "NSAttributedString", "NSObject", "__kIMMessagePartAttributeName"])
        try runSQLite(db, """
        INSERT INTO handle (ROWID, id, service)
        VALUES (1, '+15551234567', 'iMessage');
        INSERT INTO message (ROWID, guid, text, attributedBody, is_from_me, date, service, handle_id)
        VALUES (20, 'attributed-only', NULL, \(sqliteBlobLiteral(attributed)), 0, 1000000000, 'iMessage', 1);
        """)
        let source = SQLiteMessageSource(
            dbPath: db.path,
            trustedSenders: ["+15551234567"],
            homeDir: paths.homeDir.path
        )

        let latest = try await source.latestMatchingMessage()
        let messages = try await source.fetchNewMessages(afterRowId: 0)

        try expect(latest?.rowId == 20, "sqlite source latest sees attributed-body-only text")
        try expect(messages.count == 1, "sqlite source returns attributed-body-only row")
        try expect(messages[0].text == "Hello?", "sqlite source extracts user text from attributedBody")
        try expect(!messages[0].text.contains("NSAttributedString"), "attributedBody extraction filters archive metadata")
        try expect(!messages[0].text.contains("__kIMMessagePartAttributeName"), "attributedBody extraction filters Messages metadata")
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

    private static func testPreviousImageReferenceSkipsUnsupportedRecentImage() throws {
        let supportedPath = NSTemporaryDirectory() + "/bridge-recent-source-supported.png"
        let unsupportedPath = NSTemporaryDirectory() + "/bridge-recent-source-newer.heic"
        FileManager.default.createFile(atPath: supportedPath, contents: Data("png".utf8), attributes: nil)
        FileManager.default.createFile(atPath: unsupportedPath, contents: Data("heic".utf8), attributes: nil)
        let batch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-20T10:00:00.000Z",
            deadlineAt: "2026-05-20T10:00:01.000Z",
            items: [
                MessageItem(rowId: 12, guid: "follow-up", text: "Modify that image to make the background blue.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-20T10:00:00.000Z", attachments: [])
            ]
        )
        let olderSupported = RecentMediaRef(direction: "inbound", rowId: 10, handleId: "+1", service: "iMessage", path: supportedPath, transferName: "source.png", kind: "image", createdAt: "2026-05-20T09:58:00.000Z", exists: true)
        let newerUnsupported = RecentMediaRef(direction: "inbound", rowId: 11, handleId: "+1", service: "iMessage", path: unsupportedPath, transferName: "source.heic", kind: "image", createdAt: "2026-05-20T09:59:00.000Z", exists: true)

        let request = buildPromptRequest(from: batch, recentMediaRefs: [olderSupported, newerUnsupported])

        try expect(request.attachments.map(\.absolutePath) == [supportedPath], "previous image reference skips unsupported newer image and attaches older compatible image")
        try expect(latestUsableImageRef(for: "+1", service: "iMessage", recentMediaRefs: [newerUnsupported]) == nil, "unsupported recent image is not usable for app-server image input")
        try expect(recentMediaRefsStatusText([newerUnsupported]).contains("app-server-unsupported"), "status marks unsupported image refs")
    }

    private static func testLiveSmokeResultsStatusHighlightsLatestBlocker() throws {
        let results = [
            LiveSmokeResult(
                name: "chrome",
                marker: "MARKER_OLD",
                status: "passed",
                detail: "SUCCESS",
                threadId: nil,
                turnId: nil,
                updatedAt: "2026-05-22T12:00:00.000Z"
            ),
            LiveSmokeResult(
                name: "app-server-callback",
                marker: "MARKER_NEW",
                status: "blocked",
                detail: "request_user_input is unavailable in Default mode",
                threadId: "thread-callback",
                turnId: "turn-callback",
                updatedAt: "2026-05-22T12:10:00.000Z"
            )
        ]

        let text = liveSmokeResultsStatusText(results)

        try expect(text.contains("2 result(s)"), "live smoke status reports result count")
        try expect(text.contains("app-server-callback blocked"), "live smoke status highlights blocked latest result")
        try expect(text.contains("MARKER_NEW"), "live smoke status includes marker")
        try expect(text.contains("thread thread-callback"), "live smoke status includes thread id")
        try expect(text.contains("request_user_input is unavailable in Default mode"), "live smoke status includes blocker detail")
    }

    private static func testLiveSmokeResultsKeepLatestPerSmokeName() throws {
        let older = LiveSmokeResult(name: "chrome", marker: "OLD", status: "passed", detail: "old success", updatedAt: "2026-05-22T12:00:00.000Z")
        let newer = LiveSmokeResult(name: "chrome", marker: "NEW", status: "blocked", detail: "new blocker", updatedAt: "2026-05-22T12:10:00.000Z")
        let browser = LiveSmokeResult(name: "browser", marker: "BROWSER", status: "blocked", detail: "iab", updatedAt: "2026-05-22T12:05:00.000Z")

        let results = updatedLiveSmokeResults([older, browser], with: newer)

        try expect(results.count == 2, "live smoke results keep one result per smoke name")
        try expect(results.contains(where: { $0.name == "chrome" && $0.marker == "NEW" }), "live smoke results replace older same-name result")
        try expect(!results.contains(where: { $0.marker == "OLD" }), "live smoke results drop older same-name result")
        try expect(results.map(\.name) == ["browser", "chrome"], "live smoke results remain sorted by update time")
    }

    private static func testRecordLiveSmokeResultPersistsToState() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.state.save(defaultBridgeState())

        try recordLiveSmokeResult(
            stores: stores,
            name: "computer-use",
            marker: "DOCTOR_MARKER",
            status: "blocked",
            detail: "cgWindowNotFound",
            threadId: "thread-doctor",
            turnId: nil,
            updatedAt: Date(timeIntervalSince1970: 1_778_640_000)
        )

        let reloaded = try stores.state.load()
        try expect(reloaded.liveSmokeResults?.count == 1, "record live smoke result persists one result")
        try expect(reloaded.liveSmokeResults?.first?.name == "computer-use", "record live smoke result persists name")
        try expect(reloaded.liveSmokeResults?.first?.detail == "cgWindowNotFound", "record live smoke result persists detail")
        try expect(reloaded.liveSmokeResults?.first?.updatedAt == "2026-05-13T02:40:00.000Z", "record live smoke result uses supplied timestamp")
    }

    private static func testMissingPreviousImageReferenceAsksForSource() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.activeJobAckEnabled = false
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

    private static func testCodexSmokeBridgeAttachCommandUsesDirectiveHandoff() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-bridge-attach", text: "/codex smoke bridge-attach", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
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
        let events = await sink.eventsSnapshot()

        try expect(attachments.count == 1, "codex smoke bridge-attach sends one directive image")
        try expect(replies.count == 2, "codex smoke bridge-attach sends generated text plus summary")
        try expect(replies.first?.text.contains("CODEX_BRIDGE_SMOKE_BRIDGE-ATTACH_") == true, "codex smoke bridge-attach sends generated success text")
        try expect(replies.last?.text.contains("Smoke bridge-attach passed: CODEX_BRIDGE_SMOKE_BRIDGE-ATTACH_") == true, "codex smoke bridge-attach reports summary")
        try expect(events.first == "attachment:\(attachments.first!.filePath)", "codex smoke bridge-attach sends attachment first")
        try expect(!replies.contains { $0.text.contains("BRIDGE_ATTACH:") }, "codex smoke bridge-attach strips directive from Messages text")
    }

    private static func testCodexSmokeGeneratedImageStartsAppServerAndAttachesResult() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-generated-image", text: "/codex smoke generated-image", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = GeneratedImageSmokeCodexBackend()
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
        _ = try await waitForState(stores, timeout: 3) { $0.activeJob == nil }
        let attachments = await sink.attachmentsSnapshot()
        let replies = try await waitForReplies(sink, count: 2)
        let events = await sink.eventsSnapshot()
        let promptText = await backend.promptText()
        let state = try stores.state.load()
        let smokeResult = state.liveSmokeResults?.first { $0.name == "messages-generated-image" }

        try expect(promptText?.contains("BRIDGE_ATTACH:") == true, "generated-image smoke prompt asks for bridge attachment")
        try expect(attachments.count == 1, "generated-image smoke sends generated attachment")
        try expect(attachments.first?.filePath.hasSuffix(".png") == true, "generated-image smoke attaches png artifact")
        try expect(replies.contains { $0.text.contains("Smoke generated-image started: CODEX_BRIDGE_SMOKE_GENERATED-IMAGE_") }, "generated-image smoke reports start marker")
        try expect(replies.contains { $0.text.contains("CODEX_BRIDGE_SMOKE_GENERATED-IMAGE_") && $0.text.contains("SUCCESS generated image ready") }, "generated-image smoke sends app-server final text")
        guard let attachmentIndex = events.firstIndex(where: { $0.hasPrefix("attachment:") }),
              let finalTextIndex = events.firstIndex(where: { $0.contains("SUCCESS generated image ready") }) else {
            throw TestFailure(description: "Expected generated image attachment and final success text events")
        }
        try expect(attachmentIndex < finalTextIndex, "generated-image smoke sends attachment before success text")
        try expect(smokeResult?.status == "passed", "generated-image smoke persists final pass status")
        try expect(smokeResult?.threadId == "thread-generated-image", "generated-image smoke persists final thread id")
        try expect(smokeResult?.turnId == "turn-generated-image", "generated-image smoke persists final turn id")
        try expect(smokeResult?.detail.contains("SUCCESS generated image ready") == true, "generated-image smoke persists final response")
    }

    private static func testCodexSmokeEditImageCheckUsesPreviousImageAndAttachesResult() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        let sourceImage = paths.tmpDir.appendingPathComponent("previous-source.png")
        try Data("source image".utf8).write(to: sourceImage)
        var state = defaultBridgeState()
        state.recentMediaRefs = [
            RecentMediaRef(direction: "outbound", rowId: 10, handleId: "+1", service: "iMessage", path: sourceImage.path, transferName: "previous-source.png", kind: "image", createdAt: "2026-01-01T00:00:00.000Z", exists: true)
        ]
        try stores.state.save(state)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-edit-image", text: "/codex smoke edit-image-check", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = GeneratedImageSmokeCodexBackend()
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
        _ = try await waitForState(stores, timeout: 3) { $0.activeJob == nil }
        let attachments = await sink.attachmentsSnapshot()
        let replies = try await waitForReplies(sink, count: 1)
        let events = await sink.eventsSnapshot()
        let request = await backend.requestSnapshot()
        let reloaded = try stores.state.load()

        try expect(request?.attachments.map(\.absolutePath) == [sourceImage.path], "edit-image smoke passes previous source image to app-server")
        try expect(request?.promptText.contains("Modify that image") == true, "edit-image smoke uses previous-image prompt")
        try expect(attachments.count == 1, "edit-image smoke sends edited image attachment")
        try expect(attachments.first?.filePath.hasSuffix(".png") == true, "edit-image smoke attaches png artifact")
        try expect(replies.count == 1, "edit-image smoke sends one summary reply")
        try expect(replies.first?.text.contains("Smoke edit-image-check passed: CODEX_BRIDGE_SMOKE_EDIT-IMAGE-CHECK_") == true, "edit-image smoke reports pass marker")
        try expect(replies.first?.text.contains("BRIDGE_ATTACH:") == false, "edit-image smoke strips attachment directive from summary")
        guard let attachmentIndex = events.firstIndex(where: { $0.hasPrefix("attachment:") }),
              let textIndex = events.firstIndex(where: { $0.contains("Smoke edit-image-check passed:") }) else {
            throw TestFailure(description: "Expected edit image attachment and summary events")
        }
        try expect(attachmentIndex < textIndex, "edit-image smoke sends attachment before summary text")
        try expect(reloaded.recentMediaRefs?.contains(where: { $0.direction == "outbound" && $0.path == attachments.first?.filePath }) == true, "edit-image smoke records edited outbound media ref")
    }

    private static func testPreviousImageFollowUpConvertsUnsupportedLatestImage() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        let olderPng = paths.tmpDir.appendingPathComponent("older-source.png")
        let latestBmp = paths.tmpDir.appendingPathComponent("latest-source.bmp")
        try bridgeSmokePNGData().write(to: olderPng)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-s", "format", "bmp", olderPng.path, "--out", latestBmp.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        try expect(process.terminationStatus == 0, "sips creates unsupported BMP fixture")

        var state = defaultBridgeState()
        state.recentMediaRefs = [
            RecentMediaRef(direction: "inbound", rowId: 10, handleId: "+1", service: "iMessage", path: olderPng.path, transferName: "older-source.png", kind: "image", createdAt: "2026-01-01T00:00:00.000Z", exists: true),
            RecentMediaRef(direction: "inbound", rowId: 11, handleId: "+1", service: "iMessage", path: latestBmp.path, transferName: "latest-source.bmp", kind: "image", createdAt: "2026-01-01T00:00:01.000Z", exists: true)
        ]
        try stores.state.save(state)

        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 12, guid: "guid-edit-latest-bmp", text: "Modify that image to add a label.", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:02.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "converted latest image")
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
        _ = try await waitForState(stores, timeout: 3) { $0.activeJob == nil }
        let request = await backend.requestSnapshot()
        let reloaded = try stores.state.load()
        let attached = request?.attachments.first?.absolutePath

        try expect(attached != nil, "converted previous-image follow-up attaches an image")
        try expect(attached != olderPng.path, "converted previous-image follow-up does not fall back to older supported image")
        try expect(attached?.hasSuffix(".jpg") == true, "converted previous-image follow-up attaches JPEG conversion")
        try expect(reloaded.recentMediaRefs?.contains(where: { $0.rowId == 11 && $0.path == attached }) == true, "converted previous-image follow-up records converted media ref")
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
        let state = try stores.state.load()
        let smokeResult = state.liveSmokeResults?.first { $0.name == "messages-chrome" }

        try expect(replies.count == 1, "codex smoke capability sends one summary reply")
        try expect(replies.first?.text.contains("Smoke chrome passed: CODEX_BRIDGE_SMOKE_CHROME_") == true, "codex smoke capability reports marker")
        try expect(replies.first?.text.contains("Thread id: thread-smoke") == true, "codex smoke capability reports thread id")
        try expect(request?.promptText.contains("Use @Chrome") == true, "codex smoke capability prompts app-server for Chrome")
        try expect(smokeResult?.status == "passed", "messages smoke capability persists pass status")
        try expect(smokeResult?.threadId == "thread-smoke", "messages smoke capability persists thread id")
        try expect(smokeResult?.turnId == "turn-smoke", "messages smoke capability persists turn id")
        try expect(smokeResult?.detail.contains("Smoke chrome passed:") == true, "messages smoke capability persists visible summary")
    }

    private static func testCodexSmokeAppServerCommandRunsFinalAnswerProbe() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-app-server", text: "/codex smoke app-server", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "normal final answer")
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

        try expect(replies.count == 1, "codex smoke app-server sends one summary reply")
        try expect(replies.first?.text.contains("Smoke app-server passed: CODEX_BRIDGE_SMOKE_APP-SERVER_") == true, "codex smoke app-server reports marker")
        try expect(replies.first?.text.contains("Thread id: thread-smoke") == true, "codex smoke app-server reports thread id")
        try expect(request?.promptText.contains("Do not call tools") == true, "codex smoke app-server asks for a no-tool final answer")
    }

    private static func testCodexGatesCommandRepliesWithChecklist() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.allowedSender = "+1"
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-codex-gates", text: "/codex gates", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
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

        try expect(replies.count == 1, "codex gates sends one checklist reply")
        try expect(replies.first?.text.contains("Apple Messages Bridge gates:") == true, "codex gates reply has concise checklist header")
        try expect(replies.first?.text.contains("\n\nTrusted Messages gates:") == true, "codex gates reply separates paragraphs")
        try expect(replies.first?.text.contains("Live smoke blockers:") == true, "codex gates reply summarizes live blockers")
        try expect(replies.first?.text.contains("Use /codex gates verbose for the full local/CLI gate checklist.") == true, "codex gates reply points to verbose checklist")
    }

    private static func testCodexTrustedGatesCommandRepliesWithEvidence() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let db = try makeSmokeMessagesDb(paths: paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        config.allowedSender = "+1-520-609-9095"
        config.batchWindowMs = 1
        try stores.config.save(config)
        try runSQLite(db, """
        INSERT INTO handle (ROWID, id, service)
        VALUES (1, '+1 (520) 609-9095', 'iMessage');
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (1, 'guid-codex-trusted-gates', '/codex trusted-gates', 0, 0, 0, 1000000000, 'iMessage', 1);
        """)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-codex-trusted-gates", text: "/codex trusted-gates", handleId: "+1-520-609-9095", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
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

        try expect(replies.count == 1, "codex trusted-gates sends one evidence reply")
        try expect(replies.first?.text.contains("Trusted Messages gate evidence:") == true, "codex trusted-gates reply has evidence header")
        try expect(replies.first?.text.contains("/codex trusted-gates:") == false, "codex trusted-gates is an observer, not a required gate")
        try expect(replies.first?.text.contains("Next trusted command to send from Apple Messages: /codex status") == true, "codex trusted-gates names next missing command")
    }

    private static func testTrustedGateRunbookListsExactMessagesAndFollowUps() throws {
        let text = trustedGateRunbookText()

        try expect(text.contains("Trusted Messages gate runbook"), "trusted gate runbook has header")
        try expect(text.contains("1. /codex status"), "trusted gate runbook starts with status")
        try expect(text.contains("/codex smoke mcp-elicitation-callback"), "trusted gate runbook includes MCP elicitation command")
        try expect(text.contains("After `/codex smoke callback` prompts, reply exactly: callback smoke reply"), "trusted gate runbook includes callback follow-up")
        try expect(text.contains("After `/codex smoke app-server-callback` prompts, reply exactly: app-server callback smoke reply"), "trusted gate runbook includes app-server callback follow-up")
        try expect(text.contains("After `/codex smoke mcp-elicitation-callback` prompts, reply exactly: mcp elicitation smoke reply"), "trusted gate runbook includes MCP elicitation follow-up")
    }

    private static func testCodexSmokeOutboundImageCheckSendsProbeAndBuildsFollowUp() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-outbound-image", text: "/codex smoke outbound-image-check", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "outbound image attached")
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
        let attachments = await sink.attachmentsSnapshot()
        let replies = await sink.repliesSnapshot()
        let request = await backend.requestSnapshot()
        let state = try stores.state.load()

        try expect(attachments.count == 1, "codex smoke outbound-image-check sends one image probe")
        try expect(attachments.first?.filePath.hasSuffix(".png") == true, "codex smoke outbound-image-check creates png probe")
        try expect(replies.count == 1, "codex smoke outbound-image-check sends one summary reply")
        try expect(replies.first?.text.contains("Smoke outbound-image-check delivery: CODEX_BRIDGE_SMOKE_OUTBOUND-IMAGE-CHECK_") == true, "codex smoke outbound-image-check reports delivery marker")
        try expect(replies.first?.text.contains("Smoke outbound-image-check passed: CODEX_BRIDGE_SMOKE_OUTBOUND-IMAGE-CHECK_") == true, "codex smoke outbound-image-check reports app-server pass")
        try expect(request?.attachments.count == 1, "codex smoke outbound-image-check passes one image to app-server")
        try expect(request?.attachments.first?.absolutePath == attachments.first?.filePath, "codex smoke outbound-image-check passes the sent image to app-server")
        try expect(state.recentMediaRefs?.contains(where: { $0.direction == "outbound" && $0.path == attachments.first?.filePath }) == true, "codex smoke outbound-image-check records outbound media ref")
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

    private static func testCodexSmokeAppServerCallbackStartsDefaultBackendTurn() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.timeoutMs = 5_000
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-app-server-callback", text: "/codex smoke app-server-callback", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
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
        var replies = try await waitForReplies(sink, count: 2)
        try expect(replies.contains { $0.text.contains("Smoke app-server-callback started: CODEX_BRIDGE_SMOKE_APP-SERVER-CALLBACK_") }, "app-server callback smoke reports started marker")
        try expect(replies.contains { $0.text.contains("Codex needs your input to continue:") }, "app-server callback smoke sends real callback prompt")
        var state = try stores.state.load()
        try expect(state.pendingInteractiveCallback?.method == "item/tool/requestUserInput", "app-server callback smoke persists app-server callback")
        try expect(state.activeJob?.status == "waitingForUser", "app-server callback smoke leaves active job waiting for user")

        source.append(MessageItem(rowId: 2, guid: "guid-smoke-app-server-callback-answer", text: "violet", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:01.000Z", attachments: []))
        try await service.tick()
        replies = try await waitForReplies(sink, count: 4)
        try expect(replies.contains { $0.text == "Got it. I captured that reply for the pending Codex prompt." }, "app-server callback answer is acknowledged")
        try expect(replies.contains { $0.text.contains("SUCCESS callback reply: violet") }, "app-server callback smoke completes original turn")
        state = try await waitForState(stores, timeout: 3) { state in
            state.pendingInteractiveCallback == nil && state.activeJob == nil
        }
        try expect(state.codexSession.sessionId == "thread-callback", "app-server callback smoke preserves Codex thread id")
        let smokeResult = state.liveSmokeResults?.first { $0.name == "messages-app-server-callback" }
        try expect(smokeResult?.status == "passed", "app-server callback smoke persists final pass status")
        try expect(smokeResult?.threadId == "thread-callback", "app-server callback smoke persists thread id")
        try expect(smokeResult?.turnId == "turn-callback", "app-server callback smoke persists turn id")
        try expect(smokeResult?.detail.contains("SUCCESS callback reply: violet") == true, "app-server callback smoke persists final callback reply")
    }

    private static func testCodexSmokeMcpElicitationCallbackStartsDefaultBackendTurn() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.timeoutMs = 5_000
        try stores.config.save(config)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-smoke-mcp-elicitation", text: "/codex smoke mcp-elicitation-callback", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
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
        var replies = try await waitForReplies(sink, count: 2)
        try expect(replies.contains { $0.text.contains("Smoke mcp-elicitation-callback started: CODEX_BRIDGE_SMOKE_MCP-ELICITATION-CALLBACK_") }, "MCP elicitation smoke reports started marker")
        try expect(replies.contains { $0.text.contains("Codex needs your input to continue:") }, "MCP elicitation smoke sends real callback prompt")
        var state = try stores.state.load()
        try expect(state.pendingInteractiveCallback?.method == "mcpServer/elicitation/request", "MCP elicitation smoke persists elicitation callback")
        try expect(state.activeJob?.status == "waitingForUser", "MCP elicitation smoke leaves active job waiting for user")

        source.append(MessageItem(rowId: 2, guid: "guid-smoke-mcp-elicitation-answer", text: "orange", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:01.000Z", attachments: []))
        try await service.tick()
        replies = try await waitForReplies(sink, count: 4)
        try expect(replies.contains { $0.text == "Got it. I captured that reply for the pending Codex prompt." }, "MCP elicitation answer is acknowledged")
        try expect(replies.contains { $0.text.contains("SUCCESS elicitation reply: orange") }, "MCP elicitation smoke completes original turn")
        state = try await waitForState(stores, timeout: 3) { state in
            state.pendingInteractiveCallback == nil && state.activeJob == nil
        }
        let smokeResult = state.liveSmokeResults?.first { $0.name == "messages-mcp-elicitation-callback" }
        try expect(smokeResult?.status == "passed", "MCP elicitation smoke persists final pass status")
        try expect(smokeResult?.threadId == "thread-callback", "MCP elicitation smoke persists thread id")
        try expect(smokeResult?.turnId == "turn-callback", "MCP elicitation smoke persists turn id")
        try expect(smokeResult?.detail.contains("SUCCESS elicitation reply: orange") == true, "MCP elicitation smoke persists final reply")
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

    private static func testOutboundImageSmokeBuildsLocalImageRequest() throws {
        let imagePath = NSTemporaryDirectory() + "/bridge-outbound-smoke-source.png"
        FileManager.default.createFile(atPath: imagePath, contents: Data("image".utf8), attributes: nil)
        let olderInbound = RecentMediaRef(direction: "inbound", rowId: 30, handleId: "+1", service: "iMessage", path: imagePath, transferName: "inbound.png", kind: "image", createdAt: "2026-05-20T09:00:00.000Z", exists: true)
        let outbound = RecentMediaRef(direction: "outbound", rowId: 31, handleId: "+1", service: "iMessage", path: imagePath, transferName: "outbound.png", kind: "image", createdAt: "2026-05-20T10:00:00.000Z", exists: true)

        let smoke = try buildOutboundImageSmokeRequest(
            recipient: "+1",
            service: "iMessage",
            recentMediaRefs: [olderInbound, outbound],
            now: Date(timeIntervalSince1970: 1_778_640_000),
            marker: "CODEXMSGCTL_SMOKE_OUTBOUND_IMAGE_TEST"
        )

        try expect(smoke.mediaRef == outbound, "outbound image smoke chooses recent trusted outbound image")
        try expect(smoke.request.attachments.count == 1, "outbound image smoke attaches exactly one image")
        try expect(smoke.request.attachments.first?.absolutePath == imagePath, "outbound image smoke passes local image path")
        try expect(smoke.request.promptText.contains("Bridge media context:"), "outbound image smoke uses previous-image bridge context")
    }

    private static func testImageEditSmokeBuildsPreviousImageRequest() throws {
        let imagePath = NSTemporaryDirectory() + "/bridge-edit-smoke-source.png"
        let artifactPath = NSTemporaryDirectory() + "/bridge-edit-smoke-output.png"
        FileManager.default.createFile(atPath: imagePath, contents: Data("image".utf8), attributes: nil)
        let olderInbound = RecentMediaRef(direction: "inbound", rowId: 20, handleId: "+1", service: "iMessage", path: imagePath, transferName: "source.png", kind: "image", createdAt: "2026-05-20T09:00:00.000Z", exists: true)
        let newerOutbound = RecentMediaRef(direction: "outbound", rowId: 21, handleId: "+1", service: "iMessage", path: imagePath, transferName: "generated.png", kind: "image", createdAt: "2026-05-20T10:00:00.000Z", exists: true)

        let smoke = try buildImageEditSmokeRequest(
            recipient: "+1",
            service: "iMessage",
            recentMediaRefs: [olderInbound, newerOutbound],
            artifactPath: artifactPath,
            marker: "EDIT_MARKER"
        )

        try expect(smoke.marker == "EDIT_MARKER", "image edit smoke keeps marker")
        try expect(smoke.mediaRef == newerOutbound, "image edit smoke chooses latest usable chat image")
        try expect(smoke.artifactPath == artifactPath, "image edit smoke records output artifact")
        try expect(smoke.request.attachments.map(\.absolutePath) == [imagePath], "image edit smoke attaches source image")
        try expect(smoke.request.promptText.contains("Modify that image"), "image edit smoke uses previous-image language")
        try expect(smoke.request.promptText.contains("BRIDGE_ATTACH: \(artifactPath)"), "image edit smoke asks app-server for attachment directive")
    }

    private static func testAppServerCallbackSmokeResponseShapes() throws {
        let answer = "purple"
        let inputResponse = appServerCallbackSmokeResponse(
            method: "item/tool/requestUserInput",
            params: [
                "questions": [
                    ["id": "choice", "question": "Pick one"],
                    ["id": "note", "question": "Say more"]
                ]
            ],
            answer: answer
        )
        let inputResult = inputResponse["result"] as? [String: Any]
        let answers = inputResult?["answers"] as? [String: Any]
        let choice = answers?["choice"] as? [String: Any]
        let note = answers?["note"] as? [String: Any]
        try expect(choice?["answers"] as? [String] == [answer], "callback smoke fills requestUserInput choice answers")
        try expect(note?["answers"] as? [String] == [answer], "callback smoke fills every requestUserInput question")

        let elicitationResponse = appServerCallbackSmokeResponse(
            method: "mcpServer/elicitation/request",
            params: ["message": "Confirm"],
            answer: answer
        )
        let elicitationResult = elicitationResponse["result"] as? [String: Any]
        let content = elicitationResult?["content"] as? [String: Any]
        try expect(elicitationResult?["action"] as? String == "accept", "callback smoke accepts elicitation")
        try expect(content?["response"] as? String == answer, "callback smoke includes elicitation text response")
        try expect(content?["confirmed"] as? Bool == true, "callback smoke includes confirmation for elicitation schemas")

        let prompt = bridgeAppServerCallbackSmokePrompt(marker: "CALLBACK_MARKER")
        try expect(prompt.contains("CALLBACK_MARKER"), "app-server callback smoke prompt includes marker")
        try expect(prompt.contains("requestUserInput"), "app-server callback smoke prompt asks for requestUserInput")
        let mcpPrompt = bridgeAppServerMcpElicitationSmokePrompt(marker: "MCP_MARKER")
        try expect(mcpPrompt.contains("MCP_MARKER"), "MCP elicitation smoke prompt includes marker")
        try expect(mcpPrompt.contains("MCP elicitation"), "MCP elicitation smoke prompt asks for MCP elicitation")
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
        try expect(toml.contains(#"status = "INACTIVE""#), "automation smoke writes inactive automation")
        try expect(toml.contains(#"rrule = "FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=31;BYHOUR=23;BYMINUTE=59;BYSECOND=0""#), "automation smoke uses harmless far-future schedule")
        let state = try stores.state.load()
        try expect(state.automationRoutes?.contains(where: { $0.automationId == result.automation.id && $0.recipient == "+1" }) == true, "automation smoke route persisted")
        try expect(state.automationCreationStatus?.automationId == result.automation.id, "automation smoke creation status automation id")
        try expect(state.automationCreationStatus?.phase == "confirmed", "automation smoke creation status confirmed")
    }

    private static func testActiveBridgeSmokeAutomationDiagnostics() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        try writeAutomationToml(
            id: "bridge-smoke-test-active",
            name: "Bridge Smoke Test Active",
            status: "ACTIVE",
            paths: paths
        )
        try writeAutomationToml(
            id: "bridge-smoke-test-inactive",
            name: "Bridge Smoke Test Inactive",
            status: "INACTIVE",
            paths: paths
        )
        try writeAutomationToml(
            id: "ordinary-active",
            name: "Ordinary Active",
            status: "ACTIVE",
            paths: paths
        )

        let summaries = activeBridgeSmokeAutomations(in: paths.codexAutomationsDir)
        try expect(summaries.map(\.id) == ["bridge-smoke-test-active"], "only active bridge smoke automations are reported")
        let check = bridgeSmokeAutomationDiagnosticCheck(paths: paths)
        try expect(check.ok, "active bridge smoke automation diagnostic is informational")
        try expect(check.detail.contains("bridge-smoke-test-active"), "active bridge smoke automation diagnostic names active artifact")
        try expect(!check.detail.contains("bridge-smoke-test-inactive"), "active bridge smoke automation diagnostic ignores inactive artifact")

        let dryRun = try deactivateActiveBridgeSmokeAutomations(in: paths.codexAutomationsDir, dryRun: true)
        try expect(dryRun.targets.map(\.id) == ["bridge-smoke-test-active"], "dry run targets active bridge smoke automations")
        try expect(dryRun.changedPaths.isEmpty, "dry run does not change files")
        var activeToml = try String(contentsOf: paths.codexAutomationsDir.appendingPathComponent("bridge-smoke-test-active/automation.toml"), encoding: .utf8)
        try expect(activeToml.contains(#"status = "ACTIVE""#), "dry run preserves active automation status")

        let cleanup = try deactivateActiveBridgeSmokeAutomations(in: paths.codexAutomationsDir, dryRun: false)
        try expect(cleanup.targets.map(\.id) == ["bridge-smoke-test-active"], "cleanup targets active bridge smoke automations")
        try expect(cleanup.changedPaths.count == 1, "cleanup changes active smoke automation file")
        activeToml = try String(contentsOf: paths.codexAutomationsDir.appendingPathComponent("bridge-smoke-test-active/automation.toml"), encoding: .utf8)
        try expect(activeToml.contains(#"status = "INACTIVE""#), "cleanup marks active smoke automation inactive")
        try expect(activeBridgeSmokeAutomations(in: paths.codexAutomationsDir).isEmpty, "cleanup clears active smoke automation diagnostics")
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
        existing.liveSmokeResults = [
            LiveSmokeResult(
                name: "chrome",
                marker: "SMOKE_CHROME",
                status: "blocked",
                detail: "browser-client is not trusted",
                threadId: "thread-smoke",
                turnId: "turn-smoke",
                updatedAt: "2026-05-22T07:01:30.000Z"
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
        existing.lastOutboundSend = OutboundSendRecord(
            attemptId: "send-1",
            kind: "attachment",
            recipient: "+1",
            service: "iMessage",
            artifact: "/tmp/probe.png",
            status: "dbObserved",
            startedAt: "2026-05-22T07:03:00.000Z",
            completedAt: "2026-05-22T07:03:01.000Z",
            retryable: false,
            evidence: OutboundDeliveryEvidence(transport: "AppleScript+MessagesDB", dbRowId: 44, dbError: 0, transferState: 5, dateDelivered: 0),
            error: nil
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
        try expect(reloaded.liveSmokeResults?.contains(where: { $0.name == "chrome" && $0.marker == "SMOKE_CHROME" }) == true, "state save preserves concurrent live smoke results")
        try expect(liveSmokeResultsStatusText(reloaded.liveSmokeResults ?? []).contains("browser-client is not trusted"), "live smoke status exposes persisted blocker")
        try expect(reloaded.pendingInteractiveCallback?.callbackId == "callback-1", "state save preserves non-terminal pending interactive callback")
        try expect(reloaded.lastOutboundSend?.attemptId == "send-1", "state save preserves concurrent outbound send evidence")

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

        var inFlight = cleared
        inFlight.lastOutboundSend = OutboundSendRecord(
            attemptId: "send-2",
            kind: "text",
            recipient: "+1",
            service: "iMessage",
            artifact: nil,
            body: "hello",
            status: "sending",
            startedAt: "2026-05-22T07:04:00.000Z"
        )
        try stores.state.save(inFlight)
        var completedSend = cleared
        completedSend.lastOutboundSend = OutboundSendRecord(
            attemptId: "send-2",
            kind: "text",
            recipient: "+1",
            service: "iMessage",
            artifact: nil,
            body: "hello",
            status: "dbObserved",
            startedAt: "2026-05-22T07:04:00.000Z",
            completedAt: "2026-05-22T07:04:01.000Z",
            evidence: OutboundDeliveryEvidence(transport: "AppleScript+MessagesDB", dbRowId: 45, dbError: 0)
        )
        try stores.state.save(completedSend)
        let completedOutbound = try stores.state.load()
        try expect(completedOutbound.lastOutboundSend?.status == "dbObserved", "state save keeps higher-ranked outbound send status for same attempt")
        var staleSendUpdate = completedOutbound
        staleSendUpdate.lastOutboundSend = inFlight.lastOutboundSend
        try stores.state.save(staleSendUpdate)
        let preservedOutbound = try stores.state.load()
        try expect(preservedOutbound.lastOutboundSend?.status == "dbObserved", "stale outbound send update cannot downgrade completed evidence")
    }

    private static func testBridgeStateSaveMergesSameActiveJobDetails() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var existing = defaultBridgeState()
        existing.activeJob = ActiveJob(
            jobId: "job-1",
            guid: "guid-1",
            rowId: 1,
            type: "promptBatch",
            receivedAt: "2026-05-22T08:00:00.000Z",
            promptPreview: "do work",
            recipient: "+1",
            service: "iMessage",
            startedAt: "2026-05-22T08:00:00.000Z",
            lastProgressAt: "2026-05-22T08:00:02.000Z",
            lastUserUpdateAt: nil,
            lastEventAt: "2026-05-22T08:00:02.000Z",
            codexPid: 123,
            codexSessionId: "thread-1",
            codexTurnId: "turn-1",
            outputPath: "/tmp/output.txt",
            sessionLogPath: "/tmp/session.jsonl",
            status: "running",
            lastObservedSummary: "Started tool call.",
            permissionRecoveryAttempts: 1,
            waitingForPermissionSince: "2026-05-22T08:00:03.000Z",
            lastPermissionEventId: "event-1"
        )
        try stores.state.save(existing)

        var incoming = defaultBridgeState()
        incoming.activeJob = ActiveJob(
            jobId: "job-1",
            guid: "guid-1",
            rowId: 1,
            type: "promptBatch",
            receivedAt: "2026-05-22T08:00:00.000Z",
            promptPreview: "do work",
            recipient: "+1",
            service: "iMessage",
            startedAt: "2026-05-22T08:00:00.000Z",
            lastProgressAt: "2026-05-22T08:00:04.000Z",
            lastUserUpdateAt: nil,
            lastEventAt: "2026-05-22T08:00:04.000Z",
            codexPid: nil,
            codexSessionId: nil,
            codexTurnId: nil,
            outputPath: nil,
            sessionLogPath: nil,
            status: "running",
            lastObservedSummary: "Waiting for final answer.",
            permissionRecoveryAttempts: 0,
            waitingForPermissionSince: nil,
            lastPermissionEventId: nil
        )
        try stores.state.save(incoming)

        let merged = try stores.state.load().activeJob
        try expect(merged?.codexPid == 123, "same active job merge preserves process id")
        try expect(merged?.codexSessionId == "thread-1", "same active job merge preserves thread id")
        try expect(merged?.codexTurnId == "turn-1", "same active job merge preserves turn id")
        try expect(merged?.outputPath == "/tmp/output.txt", "same active job merge preserves output path")
        try expect(merged?.lastProgressAt == "2026-05-22T08:00:04.000Z", "same active job merge keeps latest progress timestamp")
        try expect(merged?.lastObservedSummary == "Waiting for final answer.", "same active job merge keeps latest summary")
        try expect(merged?.permissionRecoveryAttempts == 1, "same active job merge keeps highest recovery attempts")
        try expect(merged?.waitingForPermissionSince == "2026-05-22T08:00:03.000Z", "same active job merge preserves permission wait timestamp")

        var clear = try stores.state.load()
        clear.activeJob = nil
        try stores.state.save(clear)
        let cleared = try stores.state.load()
        try expect(cleared.activeJob == nil, "active job merge still allows terminal clear")
    }

    private static func testBridgeStateUpdateSerializesSeparateStoreInstances() throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let routeStore = RuntimeStores(paths: paths).state
        let mediaStore = RuntimeStores(paths: paths).state
        try routeStore.save(defaultBridgeState())

        let start = DispatchSemaphore(value: 0)
        let group = DispatchGroup()
        let errors = ConcurrentErrorRecorder()

        group.enter()
        DispatchQueue.global().async {
            start.wait()
            do {
                try routeStore.update { state in
                    state.automationRoutes = [
                        CodexAutomationRoute(
                            automationId: "serialized-route",
                            name: "Serialized Route",
                            recipient: "+1",
                            service: "iMessage",
                            createdFromGuid: "route-guid",
                            createdFromRowId: 100,
                            createdAt: "2026-05-22T09:00:00.000Z"
                        )
                    ]
                    Thread.sleep(forTimeInterval: 0.05)
                }
            } catch {
                errors.record(error)
            }
            group.leave()
        }

        group.enter()
        DispatchQueue.global().async {
            start.wait()
            do {
                try mediaStore.update { state in
                    state.recentMediaRefs = [
                        RecentMediaRef(
                            direction: "inbound",
                            rowId: 101,
                            handleId: "+1",
                            service: "iMessage",
                            path: "/tmp/serialized-source.png",
                            transferName: "serialized-source.png",
                            kind: "image",
                            createdAt: "2026-05-22T09:00:01.000Z",
                            exists: true
                        )
                    ]
                }
            } catch {
                errors.record(error)
            }
            group.leave()
        }

        start.signal()
        start.signal()
        try expect(group.wait(timeout: .now() + 5) == .success, "concurrent state updates complete")
        try expect(errors.isEmpty, "concurrent state updates do not throw")

        let reloaded = try routeStore.load()
        try expect(reloaded.automationRoutes?.contains(where: { $0.automationId == "serialized-route" }) == true, "serialized update keeps automation route")
        try expect(reloaded.recentMediaRefs?.contains(where: { $0.path == "/tmp/serialized-source.png" }) == true, "serialized update keeps media ref")
    }

    private static func testBridgeStateBoxSerializesConcurrentMutations() throws {
        let box = BridgeStateBox(defaultBridgeState())
        let queue = DispatchQueue(label: "BridgeStateBoxTests", attributes: .concurrent)
        let group = DispatchGroup()
        for index in 0..<50 {
            group.enter()
            queue.async {
                box.mutate { state in
                    state.lastProcessedRowId = max(state.lastProcessedRowId, Int64(index))
                    var refs = state.recentMediaRefs ?? []
                    refs.append(RecentMediaRef(
                        direction: "inbound",
                        rowId: Int64(index),
                        handleId: "+1",
                        service: "iMessage",
                        path: "/tmp/box-\(index).png",
                        transferName: "box-\(index).png",
                        kind: "image",
                        createdAt: "2026-05-22T00:00:\(String(format: "%02d", index % 60)).000Z",
                        exists: true
                    ))
                    state.recentMediaRefs = refs
                }
                group.leave()
            }
        }
        group.wait()
        let snapshot = box.snapshot()
        try expect(snapshot.lastProcessedRowId == 49, "state box preserves max row id across concurrent mutations")
        try expect(snapshot.recentMediaRefs?.count == 50, "state box preserves every concurrent media ref mutation")
    }

    private static func testBridgeServiceSessionAndJobStartMutationsUseStateOwner() throws {
        let sourcePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("BridgeCore/BridgeService.swift")
        let source = try String(contentsOf: sourcePath, encoding: .utf8)
        let forbidden = [
            "state.codexSession.lastPromptAt =",
            "state.activeJob = ActiveJob(",
            "state.codexSession.lastCompletedAt =",
            "state.codexSession.lastErrorAt =",
            "state.codexSession = CodexSessionState(",
            "state.codexSession.sessionId = result.sessionId",
            "state.codexSession.expiresAt ="
        ]
        for pattern in forbidden {
            try expect(!source.contains(pattern), "BridgeService session/job-start mutation should use state owner instead of direct pattern \(pattern)")
        }
    }

    private static func testBridgeServiceAutomationMutationsUseStateOwner() throws {
        let sourcePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("BridgeCore/BridgeService.swift")
        let source = try String(contentsOf: sourcePath, encoding: .utf8)
        let forbidden = [
            "state.automationCreationStatus =",
            "state.automationRoutes =",
            "state.automationRoutes?[index].lastSeenSessionId =",
            "state.automationRoutes?[index].lastDeliveredSessionId =",
            "state.automationRoutes?[index].lastDeliveredAt ="
        ]
        for pattern in forbidden {
            try expect(!source.contains(pattern), "BridgeService automation mutation should use state owner instead of direct pattern \(pattern)")
        }
    }

    private static func testBridgeServiceBatchAndCallbackMutationsUseStateOwner() throws {
        let sourcePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("BridgeCore/BridgeService.swift")
        let source = try String(contentsOf: sourcePath, encoding: .utf8)
        let forbidden = [
            "state.pendingBatch =",
            "state.pendingBatch?.items.append",
            "state.pendingBatch?.deadlineAt =",
            "state.pendingInteractiveCallback = callback",
            "state.pendingInteractiveCallback = nil"
        ]
        for pattern in forbidden {
            try expect(!source.contains(pattern), "BridgeService batch/callback mutation should use state owner instead of direct pattern \(pattern)")
        }
    }

    private static func testBridgeJobQueuePrioritizesCutThroughJobs() throws {
        let queue = BridgeJobQueue()
        let prompt = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-01-01T00:00:00.000Z",
            deadlineAt: "2026-01-01T00:00:01.000Z",
            items: [
                MessageItem(rowId: 1, guid: "prompt", text: "ordinary", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
            ]
        )
        let command = MessageItem(rowId: 2, guid: "command", text: "/codex status", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        let callback = MessageItem(rowId: 3, guid: "callback", text: "answer", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])

        queue.enqueuePromptBatch(prompt)
        queue.enqueueLocalCommand("/codex", command)
        queue.enqueueInteractiveCallbackReply(callback)

        guard case .localCommand? = queue.dequeueNext(hasActiveJob: true) else {
            throw TestFailure(description: "active job lets local command cut through prompt batch")
        }
        guard case .interactiveCallbackReply? = queue.dequeueNext(hasActiveJob: true) else {
            throw TestFailure(description: "active job lets callback reply cut through prompt batch")
        }
        try expect(queue.dequeueNext(hasActiveJob: true) == nil, "active job keeps prompt batch queued")
        guard case .promptBatch? = queue.dequeueNext(hasActiveJob: false) else {
            throw TestFailure(description: "prompt batch drains when no active job remains")
        }
        try expect(queue.isEmpty, "queue drains after prompt batch")
    }

    private static func testBridgeServiceUsesJobQueueOwner() throws {
        let sourcePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("BridgeCore/BridgeService.swift")
        let source = try String(contentsOf: sourcePath, encoding: .utf8)
        let forbidden = [
            "private var queue: [Job]",
            "queue.append(",
            "queue.isEmpty",
            "queue.firstIndex",
            "queue.remove("
        ]
        for pattern in forbidden {
            try expect(!source.contains(pattern), "BridgeService queue mutation should use BridgeJobQueue instead of direct pattern \(pattern)")
        }
    }

    private static func testComputerUseProbeDetailIncludesWindowDiagnostics() throws {
        let plain = computerUseProbeDetailWithWindowDiagnostics("SUCCESS Start Page", windowSummary: "Safari=1")
        try expect(plain == "SUCCESS Start Page", "successful probe text is not decorated")

        let blocked = computerUseProbeDetailWithWindowDiagnostics(
            "Computer Use server error -10005: cgWindowNotFound",
            windowSummary: "AX=true; frontmost=Safari; Safari=0; Messages=0; Finder=0"
        )
        try expect(blocked.contains("Computer Use server error -10005: cgWindowNotFound"), "blocker text is preserved")
        try expect(blocked.contains("Local accessibility windows: AX=true; frontmost=Safari; Safari=0; Messages=0; Finder=0"), "window preflight is appended")
        try expect(blocked.contains("No visible accessibility windows were reported"), "zero-window preflight is explained")
    }

    private static func testBridgeSmokePNGFixtureHasValidChunkCRCs() throws {
        let data = try bridgeSmokePNGData()
        let bytes = [UInt8](data)
        try expect(bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]), "smoke image has PNG signature")
        try expect(pngUInt32(bytes, at: 16) >= 100, "smoke image is wide enough to be visually identifiable")
        try expect(pngUInt32(bytes, at: 20) >= 24, "smoke image is tall enough to be visually identifiable")
        var offset = 8
        var sawIDAT = false
        while offset < bytes.count {
            try expect(offset + 12 <= bytes.count, "PNG chunk header fits")
            let length = pngUInt32(bytes, at: offset)
            let chunkStart = offset + 8
            let chunkEnd = chunkStart + Int(length)
            try expect(chunkEnd + 4 <= bytes.count, "PNG chunk payload fits")
            let kind = Array(bytes[(offset + 4)..<(offset + 8)])
            let storedCRC = pngUInt32(bytes, at: chunkEnd)
            let computedCRC = crc32(Array(bytes[(offset + 4)..<chunkEnd]))
            try expect(storedCRC == computedCRC, "PNG chunk \(String(bytes: kind, encoding: .ascii) ?? "?") CRC is valid")
            if kind == [0x49, 0x44, 0x41, 0x54] {
                sawIDAT = true
            }
            offset = chunkEnd + 4
            if kind == [0x49, 0x45, 0x4E, 0x44] {
                break
            }
        }
        try expect(sawIDAT, "smoke PNG has image data")
    }

    private static func pngUInt32(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        (UInt32(bytes[offset]) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
    }

    private static func crc32(_ bytes: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xffff_ffff
        for byte in bytes {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                if crc & 1 == 1 {
                    crc = (crc >> 1) ^ 0xedb8_8320
                } else {
                    crc >>= 1
                }
            }
        }
        return crc ^ 0xffff_ffff
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
        let staleSnapshot = CodexCapabilitySnapshot(capabilities: capabilities, cachedAt: "2026-05-09T00:00:00.000Z", refreshed: false, cacheAgeSeconds: staleCodexCapabilityCacheAgeSeconds)
        try expect(formatCodexCapabilityCacheLine(staleSnapshot).contains("stale >24h"), "capability cache formatter marks stale caches")
        try expect(formatCodexCapabilityCacheDetail(staleSnapshot).contains("stale >24h"), "capability cache detail marks stale caches")
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

    private static func testTrustedGateEvidenceFindsInboundCommandAndOutboundReply() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        config.allowedSender = "+1-520-609-9095"
        try runSQLite(db, """
        INSERT INTO handle (ROWID, id, service)
        VALUES (1, '+1 (520) 609-9095', 'iMessage');
        INSERT INTO handle (ROWID, id, service)
        VALUES (2, '+1 (999) 000-0000', 'iMessage');
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (70, 'inbound-status', '/codex status', 0, 0, 0, 1000000000, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (71, 'outbound-status', 'Codex bridge status: ready', 1, 0, 0, 1000000001, 'iMessage', NULL);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (72, 'inbound-smoke', '/codex smoke chrome', 0, 0, 0, 1000000002, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (73, 'outbound-smoke', 'Smoke chrome failed: exact blocker', 1, 25, 0, 1000000003, 'iMessage', NULL);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (80, 'inbound-gates', '/codex gates', 0, 0, 0, 1000000004, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (81, 'wrong-chat-outbound', 'Wrong chat reply', 1, 0, 0, 1000000005, 'iMessage', 2);
        INSERT INTO message (ROWID, guid, text, attributedBody, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (82, 'trusted-attributed-outbound', NULL, CAST('Trusted attributed reply' AS BLOB), 1, 0, 0, 1000000006, 'iMessage', 1);
        """)

        let evidence = try await trustedGateEvidence(
            config: config,
            recipient: "+1-520-609-9095",
            service: "iMessage",
            commands: ["/codex status", "/codex smoke chrome", "/codex smoke attachment", "/codex gates"]
        )

        try expect(evidence.map(\.command) == ["/codex status", "/codex smoke chrome", "/codex smoke attachment", "/codex gates"], "trusted gate evidence preserves command order")
        try expect(evidence[0].status == "observed", "trusted gate evidence observes status command")
        try expect(evidence[0].inboundRowId == 70, "trusted gate evidence records inbound row")
        try expect(evidence[0].outboundRowId == 71, "trusted gate evidence records outbound row")
        try expect(evidence[1].status == "outbound-error-25", "trusted gate evidence surfaces outbound error")
        try expect(evidence[2].status == "missing-inbound", "trusted gate evidence marks missing command")
        try expect(evidence[3].status == "observed", "trusted gate evidence observes gates command")
        try expect(evidence[3].outboundRowId == 82, "trusted gate evidence skips outgoing rows for other chats")
        try expect(evidence[3].outboundSnippet == "Trusted attributed reply", "trusted gate evidence reads attributed body snippets")
        try expect(trustedGateSummaryText(evidence) == "2/4 observed; 1 missing inbound; 1 incomplete; next /codex smoke chrome (outbound-error-25)", "trusted gate summary counts observed, missing, and incomplete commands")
        let formatted = formatTrustedGateEvidence(evidence)
        try expect(formatted.contains("/codex smoke chrome: outbound-error-25"), "trusted gate formatter includes failed command")
        try expect(formatted.contains("reply \"Smoke chrome failed: exact blocker\""), "trusted gate formatter includes reply snippet")
        try expect(formatted.contains("Missing trusted inbound commands: 1"), "trusted gate formatter summarizes missing inbound commands")
        try expect(formatted.contains("Next trusted command to send from Apple Messages: /codex smoke attachment"), "trusted gate formatter names the next missing command")
    }

    private static func testTrustedGateEvidenceTracksCallbackFollowUp() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.messagesDbPath = db.path
        config.allowedSender = "+1-520-609-9095"
        try runSQLite(db, """
        INSERT INTO handle (ROWID, id, service)
        VALUES (1, '+1 (520) 609-9095', 'iMessage');
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (90, 'inbound-callback', '/codex smoke callback', 0, 0, 0, 1000000000, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (91, 'outbound-callback-prompt', 'Smoke callback pending: CODEX_BRIDGE_SMOKE_CALLBACK_1', 1, 0, 0, 1000000001, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (100, 'inbound-app-callback', '/codex smoke app-server-callback', 0, 0, 0, 1000000010, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (101, 'outbound-app-started', 'Smoke app-server-callback started: CODEX_BRIDGE_SMOKE_APP-SERVER-CALLBACK_1', 1, 0, 0, 1000000011, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (102, 'outbound-app-prompt', 'Codex needs your input to continue: choose a color', 1, 0, 0, 1000000012, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (103, 'inbound-app-answer', 'violet', 0, 0, 0, 1000000013, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (104, 'outbound-app-ack', 'Got it. I captured that reply for the pending Codex prompt.', 1, 0, 0, 1000000014, 'iMessage', 1);
        """)

        var evidence = try await trustedGateEvidence(
            config: config,
            recipient: "+1-520-609-9095",
            service: "iMessage",
            commands: ["/codex smoke callback", "/codex smoke app-server-callback"]
        )

        try expect(evidence[0].status == "awaiting-followup", "bridge callback smoke prompt alone is not observed")
        try expect(evidence[1].status == "awaiting-completion", "app-server callback smoke reply ack alone is not final completion")
        var formatted = formatTrustedGateEvidence(evidence)
        try expect(formatted.contains("Reply in Apple Messages to complete /codex smoke callback"), "formatter names callback follow-up action")
        try expect(formatted.contains("Waiting for completion reply for /codex smoke app-server-callback"), "formatter names app-server completion action")

        try runSQLite(db, """
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (92, 'inbound-callback-answer', 'callback answer', 0, 0, 0, 1000000002, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (93, 'outbound-callback-complete', 'Smoke callback passed: CODEX_BRIDGE_SMOKE_CALLBACK_1', 1, 0, 0, 1000000003, 'iMessage', 1);
        INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered, date, service, handle_id)
        VALUES (105, 'outbound-app-final', 'CODEX_BRIDGE_SMOKE_APP-SERVER-CALLBACK_1 SUCCESS callback reply: violet', 1, 0, 0, 1000000015, 'iMessage', 1);
        """)

        evidence = try await trustedGateEvidence(
            config: config,
            recipient: "+1-520-609-9095",
            service: "iMessage",
            commands: ["/codex smoke callback", "/codex smoke app-server-callback"]
        )

        try expect(evidence[0].status == "observed", "bridge callback smoke requires follow-up answer and completion reply")
        try expect(evidence[1].status == "observed", "app-server callback smoke requires final completion reply")
        formatted = formatTrustedGateEvidence(evidence)
        try expect(formatted.contains("follow-up inbound row 92"), "formatter includes callback follow-up inbound row")
        try expect(formatted.contains("completion outbound row 105"), "formatter includes app-server callback completion row")
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

    private static func testAttachmentSendWaitsForDelayedMessagesDbRow() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        let file = paths.tmpDir.appendingPathComponent("delayed-probe.txt")
        try Data("probe".utf8).write(to: file)
        let script = paths.tmpDir.appendingPathComponent("fake-delayed-osascript.sh")
        try Data("""
        #!/bin/sh
        db=\(shellQuoted(db.path))
        (
          sleep 0.2
          /usr/bin/sqlite3 "$db" "INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered) VALUES (60, 'delayed-attachment-guid', '', 1, 0, 0); INSERT INTO attachment (ROWID, transfer_name, transfer_state) VALUES (13, 'delayed-probe.txt', 5); INSERT INTO message_attachment_join (message_id, attachment_id) VALUES (60, 13);"
        ) &
        exit 0
        """.utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let sink = AppleMessagesReplySink(
            osascriptCommand: script.path,
            messagesDbPath: db.path,
            attachmentVerificationTimeoutMs: 1_000
        )

        let evidence = try await sink.sendAttachment(recipient: "+1", service: "iMessage", filePath: file.path)

        try expect(evidence.dbRowId == 60, "attachment verification waits for delayed Messages row")
        try expect(evidence.transferState == 5, "delayed attachment evidence includes transfer state")
        try expect(evidence.detail == "Messages created an outgoing attachment row that is not yet delivered.", "delayed attachment evidence reports undelivered row")
    }

    private static func testSmsAttachmentSendUsesSmsServiceAndReportsFailedRow() async throws {
        let paths = testPaths()
        let db = try makeSmokeMessagesDb(paths: paths)
        let serviceFile = paths.tmpDir.appendingPathComponent("fake-osascript-service")
        let file = paths.tmpDir.appendingPathComponent("sms-probe.txt")
        try Data("probe".utf8).write(to: file)
        let script = paths.tmpDir.appendingPathComponent("fake-sms-osascript.sh")
        try Data("""
        #!/bin/sh
        db=\(shellQuoted(db.path))
        service_file=\(shellQuoted(serviceFile.path))
        service=""
        previous=""
        for arg in "$@"; do
          if [ "$previous" = "--" ]; then
            previous="recipient"
          elif [ "$previous" = "recipient" ]; then
            service="$arg"
            break
          else
            previous="$arg"
          fi
        done
        printf "%s" "$service" > "$service_file"
        /usr/bin/sqlite3 "$db" "INSERT INTO message (ROWID, guid, text, is_from_me, error, date_delivered) VALUES (61, 'sms-failed-attachment-guid', '', 1, 25, 0); INSERT INTO attachment (ROWID, transfer_name, transfer_state) VALUES (14, 'sms-probe.txt', 6); INSERT INTO message_attachment_join (message_id, attachment_id) VALUES (61, 14);"
        exit 0
        """.utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let sink = AppleMessagesReplySink(
            osascriptCommand: script.path,
            messagesDbPath: db.path,
            attachmentVerificationTimeoutMs: 500
        )

        do {
            _ = try await sink.sendAttachment(recipient: "+1-520-609-9095", service: "SMS", filePath: file.path)
            throw TestFailure(description: "Expected failed SMS attachment row")
        } catch let failure as OutboundDeliveryFailure {
            let service = try String(contentsOf: serviceFile, encoding: .utf8)
            try expect(service == "SMS", "attachment send passes SMS service type to AppleScript")
            try expect(failure.evidence?.dbRowId == 61, "failed SMS attachment evidence row")
            try expect(failure.evidence?.dbError == 25, "failed SMS attachment evidence error")
            try expect(failure.evidence?.transferState == 6, "failed SMS attachment evidence transfer state")
        }
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

    private static func testAppServerBackendUsesDefaultSandboxForAutomationRequests() async throws {
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
        try expect(sandboxPolicy?["type"] as? String == "dangerFullAccess", "automation requests use the normal app-server sandbox")
    }

    private static func testAppServerBackendKeepsDeveloperInstructionsTransportOnly() async throws {
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
        try expect(instructions.contains("Return plain text only"), "developer instructions include transport plain-text contract")
        try expect(instructions.contains("BRIDGE_ATTACH:"), "developer instructions include attachment transport contract")
        try expect(!instructions.contains("Current Codex capability inventory from app-server cache"), "developer instructions do not include cached capability inventory")
        try expect(!instructions.contains("Browser"), "developer instructions do not include accessible app inventory")
        try expect(!instructions.contains("chrome:Chrome"), "developer instructions do not include enabled skill inventory")
        try expect(!instructions.contains("Invocation status:"), "developer instructions do not include invocation status")
    }

    private static func testAppServerBackendDeveloperInstructionsPreventSelfRestart() async throws {
        let paths = testPaths()
        try writeCapabilityCacheWithInventory(paths: paths)
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-restart","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-restart"}}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-restart","turnId":"turn-restart","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"Done."}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-restart","turn":{"id":"turn-restart","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: paths) { fake }

        _ = try await backend.invoke(PromptRequest(promptText: "Rebuild and restart the bridge helper.", attachments: []), sessionId: nil, onEvent: nil)

        let threadStart = fake.sentMessages.first { $0["method"] as? String == "thread/start" }
        let params = threadStart?["params"] as? [String: Any]
        let instructions = params?["developerInstructions"] as? String ?? ""
        try expect(instructions.contains("Do not stop, restart, kickstart, bootout, unload, reinstall, or replace the Messages bridge helper"), "developer instructions forbid self-restarting helper")
        try expect(instructions.contains("codexmsgctl-swift start"), "developer instructions call out codexmsgctl-swift start as unsafe from Messages bridge turns")
        try expect(instructions.contains("BRIDGE_PROGRESS:"), "developer instructions tell Codex how to surface visible progress")
    }

    private static func testAppServerBackendDoesNotAddStructuredMentionsToTurnInput() async throws {
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
        try expect(mentions.isEmpty, "turn input does not include structured mention metadata")
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

    private static func testAppServerBackendReturnsDynamicToolFailureWhenMcpCallStalls() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-tool","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-tool"}}}"#,
            #"{"id":93,"method":"item/tool/call","params":{"threadId":"thread-tool","turnId":"turn-tool","callId":"call-stalled","namespace":"mcp__node_repl__","tool":"js","arguments":{"code":"while(true){}"}}}"#
        ], diagnostics: "mcp call stalled", stallWhenEmpty: true)
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 120
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        do {
            _ = try await backend.invoke(PromptRequest(promptText: "Use a dynamic MCP tool that stalls.", attachments: []), sessionId: nil, onEvent: nil)
            throw TestFailure(description: "Expected stalled dynamic tool turn to time out")
        } catch let error as CodexBackendFailure {
            try expect(error.timedOut, "stalled dynamic tool turn reports timeout")
        }

        try expect(fake.sentMethods.contains("mcpServer/tool/call"), "stalled dynamic tool is still forwarded to MCP")
        let toolReply = fake.sentMessages.first { ($0["id"] as? Int) == 93 }
        let result = toolReply?["result"] as? [String: Any]
        let contentItems = result?["contentItems"] as? [[String: Any]] ?? []
        let replyText = contentItems.compactMap { $0["text"] as? String }.joined(separator: "\n")
        try expect(result?["success"] as? Bool == false, "stalled dynamic tool response reports failure")
        try expect(replyText.contains("failed through app-server MCP forwarding"), "stalled dynamic tool response names forwarding failure")
        try expect(replyText.contains("Timed out waiting for Codex app-server response 4"), "stalled dynamic tool response includes timed-out MCP response id")
        try expect(fake.closed, "stalled dynamic tool closes app-server connection")
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

    private static func testAppServerBackendDeniesApprovalRequestsWithoutHanging() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-approval","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-approval"}}}"#,
            #"{"id":80,"method":"item/commandExecution/requestApproval","params":{"threadId":"thread-approval","turnId":"turn-approval","command":"curl example.com"}}"#,
            #"{"id":81,"method":"execCommandApproval","params":{"command":["curl","example.com"]}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-approval","turnId":"turn-approval","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"approval requests handled"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-approval","turn":{"id":"turn-approval","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }

        let response = try await backend.invoke(PromptRequest(promptText: "Exercise approval requests.", attachments: []), sessionId: nil, onEvent: nil)

        try expect(response.text == "approval requests handled", "approval requests do not hang the app-server turn")
        let commandReply = fake.sentMessages.first { ($0["id"] as? Int) == 80 }
        let commandResult = commandReply?["result"] as? [String: Any]
        try expect(commandResult?["decision"] as? String == "decline", "new command approval requests are declined explicitly")
        let legacyReply = fake.sentMessages.first { ($0["id"] as? Int) == 81 }
        let legacyResult = legacyReply?["result"] as? [String: Any]
        try expect(legacyResult?["decision"] as? String == "denied", "legacy command approval requests are denied explicitly")
    }

    private static func testAppServerBackendFailsUnsupportedServerRequestsVisibly() async throws {
        let fake = FakeCodexAppServerConnection(lines: [
            #"{"id":1,"result":{"ok":true}}"#,
            #"{"id":2,"result":{"thread":{"id":"thread-unsupported","path":"/tmp/thread.jsonl"}}}"#,
            #"{"id":3,"result":{"turn":{"id":"turn-unsupported"}}}"#,
            #"{"id":82,"method":"attestation/generate","params":{"threadId":"thread-unsupported","turnId":"turn-unsupported"}}"#,
            #"{"method":"item/completed","params":{"threadId":"thread-unsupported","turnId":"turn-unsupported","item":{"type":"agentMessage","id":"item-1","phase":"final_answer","text":"should not be accepted silently"}}}"#,
            #"{"method":"turn/completed","params":{"threadId":"thread-unsupported","turn":{"id":"turn-unsupported","status":"completed","error":null}}}"#
        ])
        var config = defaultBridgeConfig(paths: testPaths(), codexCommand: "/bin/echo")
        config.timeoutMs = 1_000
        let backend = CodexAppServerBackend(config: config, paths: testPaths()) { fake }
        let eventCollector = CodexEventCollector()

        do {
            _ = try await backend.invoke(PromptRequest(promptText: "Exercise unsupported server request.", attachments: []), sessionId: nil) { event in
                eventCollector.append(event)
            }
            throw TestFailure(description: "Expected unsupported server request to fail visibly")
        } catch let error as CodexBackendFailure {
            try expect(error.message.contains("client attestation"), "unsupported server request explains the missing client capability")
        }
        let unsupportedReply = fake.sentMessages.first { ($0["id"] as? Int) == 82 }
        let unsupportedError = unsupportedReply?["error"] as? [String: Any]
        try expect((unsupportedError?["message"] as? String)?.contains("client attestation") == true, "unsupported server request receives JSON-RPC error")
        let blockers = eventCollector.snapshot().filter { event in
            if case .blocker = event { return true }
            return false
        }
        try expect(blockers.count == 1, "unsupported server request emits a visible blocker")
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

    private static func testCodexProgressSummaryUsesCommentaryText() throws {
        let summary = codexProgressSummary(from: [
            "method": "item/completed",
            "params": [
                "item": [
                    "type": "agentMessage",
                    "phase": "commentary",
                    "text": "Verified the wrapper fix in source; rebuilding the helper next."
                ]
            ]
        ])
        try expect(summary == "Verified the wrapper fix in source; rebuilding the helper next.", "commentary agent messages become visible progress summaries")
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
        let events = await sink.eventsSnapshot()
        try expect(replies.map(\.text) == ["Done."], "visible attachment directive is stripped from text")
        try expect(attachments.map(\.filePath) == [attachment.path], "validated BRIDGE_ATTACH path sends even without prompt heuristics")
        try expect(events == ["attachment:\(attachment.path)", "text:Done."], "attachment is sent before success text")
        let state = try stores.state.load()
        try expect(state.lastOutboundSend?.kind == "attachment", "last outbound send records attachment kind")
        try expect(state.lastOutboundSend?.status == "dbObserved", "last outbound send records database observation")
        try expect(service.runLocalCommand("/status").contains("Last outbound send: attachment dbObserved"), "status exposes outbound send evidence")
    }

    private static func testBridgeAttachDirectiveDoesNotSendSuccessTextWhenAttachmentFails() async throws {
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
            MessageItem(rowId: 1, guid: "guid-attach-fails", text: "make the picture", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
        ])
        let sink = CapturingReplySink(failAttachments: true)
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
        let replies = try await waitForReplies(sink, count: 1)
        let events = await sink.eventsSnapshot()

        try expect(!events.contains("text:Done."), "success text is not sent before a failed attachment")
        try expect(replies.first?.text.contains("Could not send attachment") == true, "failed attachment sends visible error instead of success")
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

    private static func testProgressEventsSendVisibleUpdatesAfterInterval() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.longTaskProgressIntervalMs = 1
        try stores.config.save(config)
        let clock = IncrementingClock(start: Date(timeIntervalSince1970: 1_777_777_777), step: 1)
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 1, guid: "guid-progress-visible", text: "run a harmless probe", handleId: "+1", service: "iMessage", receivedAt: "2026-01-01T00:00:00.000Z", attachments: [])
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
                        .sessionStarted("thread-progress-visible"),
                        .turnStarted("turn-progress-visible"),
                        .progress("Visible progress update")
                    ],
                    response: "final answer only"
                )
            },
            now: { clock.now() }
        )

        try await service.initialize()
        try await service.tick()
        let replies = try await waitForReplies(sink, count: 2)

        try expect(replies.map(\.text) == ["Visible progress update", "final answer only"], "progress sends a visible heartbeat once the interval has elapsed")
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

    private static func testBridgeRepairDryRunReportsStaleJobAndMissedAttributedRows() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        let db = try makeSmokeMessagesDb(paths: paths)
        config.messagesDbPath = db.path
        config.allowedSender = "+1-520-609-9095"
        try stores.config.save(config)
        try insertRepairMessages(db: db)
        try stores.state.save(repairIncidentState())

        let report = try await runBridgeRepair(
            paths: paths,
            stores: stores,
            options: BridgeRepairOptions(dryRun: true, replay: true, maxReplay: 10, reloadLaunchAgents: false),
            processIsRunning: { _ in false },
            launchAgentStateProvider: { (.notLoaded, .error("Bad request.")) },
            reloadLaunchAgents: {}
        )

        try expect(report.dryRun, "repair report records dry-run mode")
        try expect(report.staleJobRecovered, "dry run reports stale active job")
        try expect(report.missedMessageRowIds == [887, 888, 889], "dry run reports attributed-body missed rows")
        try expect(report.replayRowIds == [885, 887, 888, 889], "dry run plans recoverable plus missed replay rows")
        try expect(report.helperLaunchAgentState == .notLoaded, "dry run reports helper launch state")
        try expect(report.permissionBrokerLaunchAgentState == .error("Bad request."), "dry run reports broker launch state")
        let state = try stores.state.load()
        try expect(state.activeJob != nil, "dry run leaves active job untouched")
        try expect(state.pendingBatch == nil, "dry run does not stage replay")
        try expect(state.lastProcessedRowId == 885, "dry run does not advance cursor")
    }

    private static func testBridgeRepairStagesRecoverableAndMissedRowsForReplay() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        let db = try makeSmokeMessagesDb(paths: paths)
        config.messagesDbPath = db.path
        config.allowedSender = "+1-520-609-9095"
        try stores.config.save(config)
        try insertRepairMessages(db: db)
        try stores.state.save(repairIncidentState())

        let report = try await runBridgeRepair(
            paths: paths,
            stores: stores,
            options: BridgeRepairOptions(dryRun: false, replay: true, maxReplay: 10, reloadLaunchAgents: false),
            processIsRunning: { _ in false },
            launchAgentStateProvider: { (.notLoaded, .notLoaded) },
            reloadLaunchAgents: {}
        )

        try expect(report.staleJobRecovered, "repair recovers stale active job")
        try expect(report.replayStaged, "repair stages replay")
        try expect(report.replayRowIds == [885, 887, 888, 889], "repair stages original and missed rows in chronological order")
        let state = try stores.state.load()
        try expect(state.activeJob == nil, "repair clears stale active job")
        try expect(state.lastRecoverablePromptBatch == nil, "repair consumes recoverable batch into replay")
        try expect(state.pendingBatch?.items.map(\.rowId) == [885, 887, 888, 889], "repair pending batch contains replay rows")
        try expect(state.pendingBatch?.items.map(\.text).contains("Hello?") == true, "repair replay includes attributed-body text")
        try expect(state.lastProcessedRowId == 889, "repair advances cursor past staged missed rows")
    }

    private static func testBridgeRepairNoReplayReportsAndAdvancesPastMissedRows() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        let db = try makeSmokeMessagesDb(paths: paths)
        config.messagesDbPath = db.path
        config.allowedSender = "+1-520-609-9095"
        try stores.config.save(config)
        try insertRepairMessages(db: db)
        try stores.state.save(repairIncidentState())

        let report = try await runBridgeRepair(
            paths: paths,
            stores: stores,
            options: BridgeRepairOptions(dryRun: false, replay: false, maxReplay: 10, reloadLaunchAgents: false),
            processIsRunning: { _ in false },
            launchAgentStateProvider: { (.notLoaded, .notLoaded) },
            reloadLaunchAgents: {}
        )

        try expect(!report.replayStaged, "no-replay does not stage replay")
        try expect(report.missedMessageRowIds == [887, 888, 889], "no-replay reports missed rows")
        let state = try stores.state.load()
        try expect(state.activeJob == nil, "no-replay clears stale active job")
        try expect(state.pendingBatch == nil, "no-replay leaves no pending batch")
        try expect(state.lastRecoverablePromptBatch?.items.map(\.rowId) == [885], "no-replay preserves recoverable original batch for explicit retry")
        try expect(state.lastProcessedRowId == 889, "no-replay advances cursor so missed rows are report-only")
    }

    private static func testTryAgainReplaysRecoveredActiveJobBatch() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        var config = defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo")
        config.batchWindowMs = 1
        config.activeJobAckEnabled = false
        try stores.config.save(config)
        let originalBatch = PendingBatch(
            handleId: "+1",
            service: "iMessage",
            startedAt: "2026-05-22T19:29:02.000Z",
            deadlineAt: "2026-05-22T19:29:03.000Z",
            items: [
                MessageItem(rowId: 42, guid: "dead-guid", text: "Use Computer Use to play Dungeon Crawl Stone Soup.", handleId: "+1", service: "iMessage", receivedAt: "2026-05-22T19:29:02.000Z", attachments: [])
            ]
        )
        try stores.state.save(BridgeState(
            lastProcessedGuid: nil,
            lastProcessedRowId: 42,
            pendingBatch: nil,
            activeJob: ActiveJob(
                jobId: "dead-job",
                guid: "dead-guid",
                rowId: 42,
                type: "promptBatch",
                receivedAt: "2026-05-22T19:29:02.000Z",
                promptPreview: "Use Computer Use to play Dungeon Crawl Stone Soup.",
                recipient: "+1",
                service: "iMessage",
                startedAt: "2026-05-22T19:29:02.000Z",
                lastProgressAt: nil,
                lastUserUpdateAt: nil,
                lastEventAt: "2026-05-22T19:29:15.000Z",
                codexPid: 999_999,
                codexSessionId: "thread-dead",
                outputPath: nil,
                sessionLogPath: nil,
                status: "running",
                lastObservedSummary: "Started Computer Use.",
                permissionRecoveryAttempts: 0,
                waitingForPermissionSince: nil,
                lastPermissionEventId: nil,
                recoverableBatch: originalBatch
            ),
            codexSession: CodexSessionState(sessionId: "thread-dead", startedAt: nil, lastPromptAt: nil, lastCompletedAt: nil, expiresAt: nil, lastErrorAt: nil)
        ))
        let source = QueueMessageSource(messages: [
            MessageItem(rowId: 43, guid: "retry-guid", text: "Ok try again", handleId: "+1", service: "iMessage", receivedAt: "2026-05-22T19:36:38.000Z", attachments: [])
        ])
        let sink = CapturingReplySink()
        let backend = CapturingCodexBackend(response: "replayed")
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in backend },
            now: { Date(timeIntervalSince1970: 1_779_478_800) }
        )

        try await service.initialize()
        try await service.tick()
        try await service.tick()

        let replies = try await waitForReplies(sink, count: 2)
        try expect(replies.first?.text == "That active job stopped before it could finish, so I cleared it. Reply \"try again\" to rerun the original request.", "dead recoverable job sends retry hint")
        try expect(replies.map(\.text).contains { $0.contains("SUCCESS replayed") }, "retry follow-up replays the original request: \(replies.map(\.text))")
        let request = await backend.requestSnapshot()
        try expect(request?.promptText.contains("Use Computer Use to play Dungeon Crawl Stone Soup.") == true, "replayed prompt contains original request")
        try expect(request?.promptText.contains("Ok try again") == false, "replayed prompt does not replace original with retry text")
        let state = try stores.state.load()
        try expect(state.lastRecoverablePromptBatch == nil, "successful retry clears recoverable batch")
        try expect(state.activeJob == nil, "successful retry clears active job")
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

    private static func testLaunchAgentLoadStateFormatting() throws {
        try expect(LaunchAgentLoadState.loaded.statusText == "loaded", "loaded launch state text")
        try expect(LaunchAgentLoadState.notLoaded.statusText == "not loaded", "not loaded launch state text")
        try expect(LaunchAgentLoadState.error("Bad request.").statusText == "error: Bad request.", "error launch state text includes detail")
        try expect(LaunchAgentLoadState.notLoaded.isLoaded == false, "not loaded launch state is not loaded")
        try expect(LaunchAgentLoadState.loaded.isLoaded, "loaded launch state is loaded")
    }

    private static func testRuntimeExecutableIdentityDiagnostics() throws {
        let paths = testPaths()
        try FileManager.default.createDirectory(at: paths.builtHelperExecutablePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: paths.installedHelperExecutablePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("same helper".utf8).write(to: paths.builtHelperExecutablePath)
        try Data("same helper".utf8).write(to: paths.installedHelperExecutablePath)

        let matching = runtimeExecutableIdentityCheck(
            name: "Helper built-vs-installed identity",
            built: paths.builtHelperExecutablePath,
            installed: paths.installedHelperExecutablePath
        )
        try expect(matching.ok, "runtime identity passes for matching executables")
        try expect(matching.detail.contains("match"), "runtime identity reports match")

        try Data("different helper".utf8).write(to: paths.installedHelperExecutablePath)
        let mismatched = runtimeExecutableIdentityCheck(
            name: "Helper built-vs-installed identity",
            built: paths.builtHelperExecutablePath,
            installed: paths.installedHelperExecutablePath
        )
        try expect(!mismatched.ok, "runtime identity fails for mismatched executables")
        try expect(mismatched.detail.contains("mismatch"), "runtime identity reports mismatch")

        try FileManager.default.removeItem(at: paths.builtHelperExecutablePath)
        let notComparable = runtimeExecutableIdentityCheck(
            name: "Helper built-vs-installed identity",
            built: paths.builtHelperExecutablePath,
            installed: paths.installedHelperExecutablePath
        )
        try expect(notComparable.ok, "runtime identity is non-fatal when built artifact is absent")
        try expect(notComparable.detail.contains("Not comparable"), "runtime identity explains missing built artifact")
    }

    private static func testBridgeGateChecklistEnumeratesLocalAndTrustedGates() throws {
        let text = bridgeGateChecklistText(context: BridgeGateChecklistContext(
            allowedSender: "+1",
            service: "iMessage",
            hasActiveJob: false,
            hasPendingInteractiveCallback: false,
            hasRecentInboundImage: false,
            hasRecentOutboundImage: false,
            activeBridgeSmokeAutomations: [
                CodexAutomationFileSummary(
                    id: "bridge-smoke-test-active",
                    name: "Bridge Smoke Test Active",
                    status: "ACTIVE",
                    path: "/tmp/bridge-smoke-test-active/automation.toml"
                )
            ],
            liveSmokeResults: [
                LiveSmokeResult(
                    name: "mcp-elicitation-callback",
                    marker: "CODEXMSGCTL_SMOKE_MCP_ELICITATION_CALLBACK_TEST",
                    status: "blocked",
                    detail: "BLOCKED request_user_input is unavailable in Default mode",
                    threadId: "thread-1",
                    turnId: "turn-1",
                    updatedAt: "2026-05-22T13:00:00.000Z"
                )
            ]
        ))
        try expect(text.contains("swift run BridgeCoreTests"), "gate checklist includes focused tests")
        try expect(text.contains("swift run codexmsgctl-swift doctor --probe-computer-use"), "gate checklist includes doctor probe")
        try expect(text.contains("swift run codexmsgctl-swift trusted-gates"), "gate checklist includes trusted gate observer")
        try expect(text.contains("swift run codexmsgctl-swift gates --strict"), "gate checklist includes strict gate command")
        try expect(text.contains("swift run codexmsgctl-swift smoke outbound-image-check --recipient +1 --service iMessage"), "gate checklist includes outbound image smoke")
        try expect(text.contains("swift run codexmsgctl-swift smoke bridge-attach --recipient +1 --service iMessage"), "gate checklist includes bridge attach smoke")
        try expect(text.contains("swift run codexmsgctl-swift smoke generated-image --recipient +1 --service iMessage"), "gate checklist includes CLI generated image smoke")
        try expect(text.contains("swift run codexmsgctl-swift smoke edit-image-check --recipient +1 --service iMessage"), "gate checklist includes CLI edit image smoke")
        try expect(text.contains("swift run codexmsgctl-swift smoke app-server-callback"), "gate checklist includes CLI app-server callback smoke")
        try expect(text.contains("swift run codexmsgctl-swift smoke mcp-elicitation-callback"), "gate checklist includes CLI MCP elicitation callback smoke")
        try expect(text.contains("swift run codexmsgctl-swift smoke automation --deactivate-active --dry-run"), "gate checklist includes active smoke automation cleanup dry-run")
        try expect(text.contains("/codex smoke generated-image"), "gate checklist includes generated image smoke")
        try expect(text.contains("/codex smoke edit-image-check"), "gate checklist includes trusted edit image smoke")
        try expect(text.contains("Trusted evidence observer:"), "gate checklist separates trusted evidence observer")
        try expect(text.contains("swift run codexmsgctl-swift trusted-gates --runbook"), "gate checklist includes trusted gate runbook")
        try expect(text.contains("/codex smoke callback, then reply with any short text"), "gate checklist includes two-step trusted callback smoke")
        try expect(text.contains("/codex smoke app-server-callback, then reply to the app-server prompt"), "gate checklist includes real app-server callback smoke")
        try expect(text.contains("/codex smoke mcp-elicitation-callback, then reply to the MCP elicitation prompt"), "gate checklist includes real MCP elicitation callback smoke")
        try expect(text.contains("Live smoke evidence: 1 result(s); latest: mcp-elicitation-callback blocked"), "gate checklist includes live smoke blocker evidence")
        try expect(text.contains("Bridge smoke automations: warning: 1 active bridge smoke automation(s): bridge-smoke-test-active"), "gate checklist includes active smoke automation warning")
        try expect(text.contains("needs trusted inbound image first"), "gate checklist reports inbound image readiness")
        try expect(text.contains("will create a marked outbound image"), "gate checklist reports outbound image readiness")
    }

    private static func testBridgeGateStrictReportFailsOnTrustedAndLiveBlockers() throws {
        let context = BridgeGateChecklistContext(
            allowedSender: "+1",
            service: "iMessage",
            hasActiveJob: false,
            hasPendingInteractiveCallback: false,
            hasRecentInboundImage: true,
            hasRecentOutboundImage: true,
            activeBridgeSmokeAutomations: [
                CodexAutomationFileSummary(
                    id: "bridge-smoke-test-active",
                    name: "Bridge Smoke Test Active",
                    status: "ACTIVE",
                    path: "/tmp/bridge-smoke-test-active/automation.toml"
                )
            ],
            liveSmokeResults: [
                LiveSmokeResult(
                    name: "mcp-elicitation-callback",
                    marker: "MARKER",
                    status: "blocked",
                    detail: "request_user_input is unavailable in Default mode",
                    updatedAt: "2026-05-22T13:00:00.000Z"
                ),
                LiveSmokeResult(
                    name: "chrome",
                    marker: "CHROME_MARKER",
                    status: "blocked",
                    detail: "privileged native pipe bridge is not available; browser-client is not trusted",
                    updatedAt: "2026-05-22T13:01:00.000Z"
                )
            ]
        )
        let report = bridgeGateStrictReport(
            context: context,
            trustedGateEvidence: [
                TrustedGateEvidence(command: "/codex status"),
                TrustedGateEvidence(command: "/codex gates", inboundRowId: 1, outboundRowId: 2, outboundError: 0)
            ]
        )

        try expect(!report.ok, "strict gate report fails while trusted gates or live smokes are open")
        try expect(report.text.contains("Strict gate check failed."), "strict gate report has failure header")
        try expect(report.text.contains("Trusted Messages gates: 1/2 observed; 1 missing inbound; next /codex status (missing-inbound)"), "strict gate report includes trusted gate summary")
        try expect(report.text.contains("Live smoke blockers: mcp-elicitation-callback blocked MARKER request_user_input is unavailable in Default mode"), "strict gate report includes hard live smoke blocker with detail")
        try expect(report.text.contains("Accepted live capability blockers: chrome blocked CHROME_MARKER privileged native pipe bridge is not available"), "strict gate report keeps accepted capability blocker visible")
        try expect(report.text.contains("Bridge smoke automations: warning: 1 active bridge smoke automation(s): bridge-smoke-test-active"), "strict gate report includes active smoke automation warning")
        try expect(report.text.contains("Bridge smoke automation cleanup: swift run codexmsgctl-swift smoke automation --deactivate-active --dry-run"), "strict gate report includes smoke automation cleanup command")
    }

    private static func testBridgeGateStrictReportAcceptsCapabilityBlockersWithEvidence() throws {
        let context = BridgeGateChecklistContext(
            allowedSender: "+1",
            service: "iMessage",
            hasActiveJob: false,
            hasPendingInteractiveCallback: false,
            hasRecentInboundImage: true,
            hasRecentOutboundImage: true,
            liveSmokeResults: [
                LiveSmokeResult(
                    name: "messages-browser",
                    marker: "BROWSER_MARKER",
                    status: "blocked",
                    detail: "Browser is not available: iab",
                    updatedAt: "2026-05-22T13:00:00.000Z"
                ),
                LiveSmokeResult(
                    name: "computer-use-doctor",
                    marker: "CU_MARKER",
                    status: "blocked",
                    detail: "Computer Use server error -10005: cgWindowNotFound",
                    updatedAt: "2026-05-22T13:01:00.000Z"
                )
            ]
        )
        let report = bridgeGateStrictReport(
            context: context,
            trustedGateEvidence: [
                TrustedGateEvidence(command: "/codex status", inboundRowId: 1, outboundRowId: 2, outboundError: 0),
                TrustedGateEvidence(command: "/codex gates", inboundRowId: 3, outboundRowId: 4, outboundError: 0)
            ]
        )

        try expect(report.ok, "strict gate accepts capability blockers when exact blocker evidence is present")
        try expect(report.text.contains("Strict gate check passed."), "strict report passes when only exact capability blockers remain")
        try expect(report.text.contains("Accepted live capability blockers: computer-use-doctor blocked CU_MARKER Computer Use server error -10005: cgWindowNotFound; messages-browser blocked BROWSER_MARKER Browser is not available: iab"), "strict report lists accepted capability blockers")
    }

    private static func testAutomationRequestStartsNormalCodexJob() async throws {
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
        let backend = CapturingCodexBackend(response: "I'll create that with Codex.")
        let service = BridgeService(
            paths: paths,
            stores: stores,
            makeSource: { _ in source },
            makeReplySink: { _ in sink },
            makeCodex: { _ in backend },
            now: { Date(timeIntervalSince1970: 1_778_640_000) }
        )

        try await service.initialize()
        try await service.tick()
        let replies = try await waitForReplies(sink, count: 1)
        let request = await backend.requestSnapshot()
        let state = try await waitForState(stores, timeout: 3) { $0.activeJob == nil }

        try expect(replies.first?.text.contains("I'll create that with Codex.") == true, "automation-looking request is answered by normal Codex job")
        try expect(request?.promptText.contains("Can we create a new automation?") == true, "automation-looking request reaches Codex unchanged")
        try expect(request?.promptText.contains("Bridge routing guard:") == false, "automation-looking request has no routing guard")
        try expect(!FileManager.default.fileExists(atPath: paths.codexAutomationsDir.appendingPathComponent("morning-news-and-weather-digest/automation.toml").path), "normal message flow does not create native automation files")
        try expect(state.codexSession.sessionId == "thread-smoke", "normal Codex job mutates Codex session")
        try expect(state.automationCreationStatus == nil, "normal message flow does not record automation creation status")
        try expect((state.automationRoutes ?? []).isEmpty, "normal message flow does not create automation routes")
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

    private static func testCodexAutomationsReportsConfirmedCreationEvidence() async throws {
        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
        var state = defaultBridgeState()
        state.automationCreationStatus = AutomationCreationStatus(
            automationId: "bridge-smoke-test",
            name: "Bridge Smoke Test",
            sourceRowId: 725,
            sourceGuid: "guid-smoke",
            phase: "confirmed",
            createdFilePath: "/Users/moss/.codex/automations/bridge-smoke-test/automation.toml",
            routeStatus: "route persisted",
            confirmationSendStatus: "text dbObserved; db row 999",
            updatedAt: "2026-05-22T00:00:00.000Z"
        )
        state.automationRoutes = [
            CodexAutomationRoute(
                automationId: "bridge-smoke-test",
                name: "Bridge Smoke Test",
                recipient: "+1",
                service: "iMessage",
                createdFromGuid: "guid-smoke",
                createdFromRowId: 725,
                createdAt: "2026-05-22T00:00:00.000Z"
            )
        ]
        try writeAutomationToml(
            id: "bridge-smoke-test",
            name: "Bridge Smoke Test",
            status: "ACTIVE",
            paths: paths
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

        try expect(text.contains("Automation creation confirmed: Bridge Smoke Test"), "/codex automations reports confirmed creation")
        try expect(text.contains("Created file: /Users/moss/.codex/automations/bridge-smoke-test/automation.toml"), "/codex automations includes confirmed file")
        try expect(text.contains("Confirmation send: text dbObserved; db row 999"), "/codex automations includes confirmation send evidence")
        try expect(text.contains("Bridge smoke automations: warning: 1 active bridge smoke automation(s): bridge-smoke-test"), "/codex automations includes active smoke automation warning")
        try expect(text.contains("Codex automation routes:"), "/codex automations still lists routes")
    }

    private static func testNormalTickDoesNotForwardCompletedAutomationSessions() async throws {
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
        try expect(replies.isEmpty, "normal tick does not forward completed automation sessions")
        let state = try stores.state.load()
        let route = try expectRoute(state.automationRoutes?.first)
        try expect(route.lastSeenSessionId == nil, "normal tick does not scan automation sessions")
        try expect(route.lastDeliveredSessionId == nil, "normal tick does not mark automation sessions delivered")
    }

    private static func testAutomationForwardOnceSidecar() async throws {
        let emptyPaths = testPaths()
        try ensureRuntimeDirectories(emptyPaths)
        let emptyStores = RuntimeStores(paths: emptyPaths)
        try emptyStores.config.save(defaultBridgeConfig(paths: emptyPaths, codexCommand: "/bin/echo"))
        let emptySink = CapturingReplySink()
        let emptyResult = try await forwardCompletedAutomationRunsOnce(
            paths: emptyPaths,
            stores: emptyStores,
            replySink: emptySink,
            now: Date(timeIntervalSince1970: 1_778_650_000),
            maximumFilesToRead: 10
        )
        try expect(emptyResult.forwardedCount == 0, "sidecar forwards nothing when no routes exist")
        try expect(emptyResult.scan.readFileCount == 0, "sidecar does not scan sessions when no routes exist")

        let paths = testPaths()
        try ensureRuntimeDirectories(paths)
        let stores = RuntimeStores(paths: paths)
        try stores.config.save(defaultBridgeConfig(paths: paths, codexCommand: "/bin/echo"))
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

        let cappedSink = CapturingReplySink()
        let cappedResult = try await forwardCompletedAutomationRunsOnce(
            paths: paths,
            stores: stores,
            replySink: cappedSink,
            now: Date(timeIntervalSince1970: 1_778_650_000),
            maximumFilesToRead: 0
        )
        try expect(cappedResult.forwardedCount == 0, "sidecar honors max-files cap")
        try expect(cappedResult.scan.readFileCount == 0, "sidecar reads no files when capped at zero")
        let cappedReplies = await cappedSink.repliesSnapshot()
        try expect(cappedReplies.isEmpty, "sidecar sends no replies when capped before reading")

        let sink = CapturingReplySink()
        let result = try await forwardCompletedAutomationRunsOnce(
            paths: paths,
            stores: stores,
            replySink: sink,
            now: Date(timeIntervalSince1970: 1_778_650_000),
            maximumFilesToRead: 10
        )
        let replies = await sink.repliesSnapshot()
        try expect(result.forwardedCount == 1, "sidecar forwards one completed automation run")
        try expect(result.scan.readFileCount == 1, "sidecar scans within bounded file limit")
        try expect(replies.map(\.text) == ["Morning Digest\nBring an umbrella."], "sidecar forwards completed automation final answer")
        let state = try stores.state.load()
        let route = try expectRoute(state.automationRoutes?.first)
        try expect(route.lastSeenSessionId == "019e20ff-4dca-7571-9425-0713bddb0d73", "sidecar records seen session")
        try expect(route.lastDeliveredSessionId == "019e20ff-4dca-7571-9425-0713bddb0d73", "sidecar records delivered session")

        let repeatSink = CapturingReplySink()
        let repeatResult = try await forwardCompletedAutomationRunsOnce(
            paths: paths,
            stores: stores,
            replySink: repeatSink,
            now: Date(timeIntervalSince1970: 1_778_650_010),
            maximumFilesToRead: 10
        )
        try expect(repeatResult.forwardedCount == 0, "sidecar does not redeliver an already delivered route")
        let repeatReplies = await repeatSink.repliesSnapshot()
        try expect(repeatReplies.isEmpty, "already delivered route produces no sidecar reply")
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
        let db = try makeSmokeMessagesDb(paths: paths)
        config.messagesDbPath = db.path
        config.batchWindowMs = 10_000
        config.allowedSender = "+1"
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
        try expect(reply.text.contains("Active job: running"), "status reply active job")
        try expect(reply.text.contains("Recent media: 0 ref(s)"), "status reply summarizes media instead of dumping refs")
        try expect(reply.text.contains("Use /codex status verbose for full diagnostics."), "status reply points to verbose diagnostics")
        try expect(!reply.text.contains("Latest Codex progress: Running command."), "status reply is concise by default")
        try expect(reply.text.contains("Trusted Messages gates: 0/17 observed; 17 missing inbound; next /codex status (missing-inbound)"), "status reply summarizes trusted gate evidence")
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
    private let stallWhenEmpty: Bool
    private(set) var sentMethods: [String] = []
    private(set) var sentMessages: [[String: Any]] = []
    private(set) var closed = false

    init(lines: [String], diagnostics: String = "", stallWhenEmpty: Bool = false) {
        self.lines = lines
        self.diagnosticsText = diagnostics
        self.stallWhenEmpty = stallWhenEmpty
    }

    var diagnostics: String { diagnosticsText }
    var processIdentifier: Int32? { 4242 }

    func start() throws {}

    func send(_ message: [String: Any]) throws {
        sentMethods.append(message["method"] as? String ?? "")
        sentMessages.append(message)
    }

    func readLine(deadline: Date) throws -> String? {
        if !lines.isEmpty {
            return lines.removeFirst()
        }
        if stallWhenEmpty {
            while Date() < deadline, !closed {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        return nil
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

private actor GeneratedImageSmokeCodexBackend: CodexBackend {
    private var request: PromptRequest?

    func promptText() -> String? {
        request?.promptText
    }

    func requestSnapshot() -> PromptRequest? {
        request
    }

    func invoke(_ request: PromptRequest, sessionId: String?, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse {
        self.request = request
        onEvent?(.sessionStarted("thread-generated-image"))
        onEvent?(.turnStarted("turn-generated-image"))
        let marker = request.promptText.components(separatedBy: .whitespacesAndNewlines)
            .first { $0.hasPrefix("CODEX_BRIDGE_SMOKE_") }?
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;"))
            ?? "CODEX_BRIDGE_SMOKE_UNKNOWN"
        guard let artifactPath = request.promptText.components(separatedBy: .newlines).compactMap({ line -> String? in
            let generatedPrefix = "Create a small valid PNG image file at this exact path: "
            let editPrefix = "Save the edited result as a valid PNG at this exact path:"
            if line.hasPrefix(generatedPrefix) {
                return String(line.dropFirst(generatedPrefix.count))
            }
            if line == editPrefix {
                return nil
            }
            if line.hasPrefix("/") && line.hasSuffix(".png") {
                return line
            }
            return nil
        }).first else {
            throw TestFailure(description: "Generated image smoke prompt did not include artifact path")
        }
        try Data("fake png".utf8).write(to: URL(fileURLWithPath: artifactPath))
        return CodexResponse(
            text: "\(marker) SUCCESS generated image ready.\nBRIDGE_ATTACH: \(artifactPath)",
            sessionId: "thread-generated-image",
            stdout: "",
            stderr: "",
            args: [],
            outputPath: artifactPath
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
        let isElicitationSmoke = request.promptText.contains("MCP elicitation smoke test")
        let method = isElicitationSmoke ? "mcpServer/elicitation/request" : "item/tool/requestUserInput"
        let params: [String: Any] = isElicitationSmoke
            ? ["message": "Confirm MCP elicitation answer"]
            : [
                "questions": [
                    [
                        "id": "choice",
                        "header": "Test",
                        "question": "Choose a test answer"
                    ]
                ]
            ]
        let reply = try responder(method, 80, params)
        let answer: String
        if isElicitationSmoke {
            let result = reply["result"] as? [String: Any]
            let content = result?["content"] as? [String: Any]
            answer = content?["response"] as? String ?? ""
        } else {
            let result = reply["result"] as? [String: Any]
            let answers = result?["answers"] as? [String: Any]
            let choice = answers?["choice"] as? [String: Any]
            let values = choice?["answers"] as? [String]
            answer = values?.first ?? ""
        }
        let appServerMarker = request.promptText.components(separatedBy: .whitespacesAndNewlines)
            .first { $0.hasPrefix("CODEX_BRIDGE_SMOKE_APP-SERVER-CALLBACK_") }?
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;"))
        let mcpMarker = request.promptText.components(separatedBy: .whitespacesAndNewlines)
            .first { $0.hasPrefix("CODEX_BRIDGE_SMOKE_MCP-ELICITATION-CALLBACK_") }?
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;"))
        let text = mcpMarker.map { "\($0) SUCCESS elicitation reply: \(answer)" }
            ?? appServerMarker.map { "\($0) SUCCESS callback reply: \(answer)" }
            ?? "Callback completed with \(answer)."
        return CodexResponse(
            text: text,
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
    private let failAttachments: Bool

    init(failAttachments: Bool = false) {
        self.failAttachments = failAttachments
    }

    func repliesSnapshot() async -> [Reply] {
        await collector.snapshot()
    }
    func attachmentsSnapshot() async -> [Attachment] {
        await collector.attachmentsSnapshot()
    }
    func eventsSnapshot() async -> [String] {
        await collector.eventsSnapshot()
    }

    func sendReply(recipient: String, service: String, text: String) async throws -> OutboundDeliveryEvidence {
        await collector.append(Reply(recipient: recipient, service: service, text: text))
        return OutboundDeliveryEvidence(transport: "test", detail: "captured text reply")
    }

    func sendAttachment(recipient: String, service: String, filePath: String) async throws -> OutboundDeliveryEvidence {
        await collector.append(Attachment(recipient: recipient, service: service, filePath: filePath))
        if failAttachments {
            throw OutboundDeliveryFailure(message: "simulated attachment failure")
        }
        return OutboundDeliveryEvidence(transport: "test", dbRowId: 123, detail: "captured attachment")
    }
}

private actor ReplyCollector {
    private var replies: [CapturingReplySink.Reply] = []
    private var attachments: [CapturingReplySink.Attachment] = []
    private var events: [String] = []

    func append(_ reply: CapturingReplySink.Reply) {
        replies.append(reply)
        events.append("text:\(reply.text)")
    }
    func append(_ attachment: CapturingReplySink.Attachment) {
        attachments.append(attachment)
        events.append("attachment:\(attachment.filePath)")
    }

    func snapshot() -> [CapturingReplySink.Reply] {
        replies
    }
    func attachmentsSnapshot() -> [CapturingReplySink.Attachment] {
        attachments
    }
    func eventsSnapshot() -> [String] {
        events
    }
}

private final class IncrementingClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private let step: TimeInterval

    init(start: Date, step: TimeInterval) {
        self.current = start
        self.step = step
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        let value = current
        current = current.addingTimeInterval(step)
        return value
    }
}

private actor CapturingStreamPublisher {
    enum Mode {
        case success(publicUrl: String, commitHash: String, crosspostsJson: String? = nil)
        case failure(phase: String, error: String, stderr: String)
    }

    private let mode: Mode
    private let delayNanoseconds: UInt64
    private var invocations: [StreamPublishInvocation] = []
    private var running = 0
    private var maxConcurrent = 0

    init(mode: Mode, delayNanoseconds: UInt64 = 0) {
        self.mode = mode
        self.delayNanoseconds = delayNanoseconds
    }

    func run(_ invocation: StreamPublishInvocation) async -> StreamPublishProcessResult {
        running += 1
        maxConcurrent = max(maxConcurrent, running)
        invocations.append(invocation)
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        defer { running -= 1 }
        switch mode {
        case .success(let publicUrl, let commitHash, let crosspostsJson):
            let crosspostsField = crosspostsJson.map { #","crossposts":"# + $0 } ?? ""
            let json = """
            {"success":true,"phase":"verify","publicUrl":"\(publicUrl)","commitHash":"\(commitHash)"\(crosspostsField)}
            """
            try? Data(json.utf8).write(to: URL(fileURLWithPath: invocation.resultJsonPath))
            return StreamPublishProcessResult(stdout: "published \(publicUrl)", stderr: "", exitCode: 0)
        case .failure(let phase, let error, let stderr):
            let json = """
            {"success":false,"phase":"\(phase)","error":"\(error)"}
            """
            try? Data(json.utf8).write(to: URL(fileURLWithPath: invocation.resultJsonPath))
            return StreamPublishProcessResult(stdout: "", stderr: stderr, exitCode: 1)
        }
    }

    func invocationsSnapshot() -> [StreamPublishInvocation] {
        invocations
    }

    func maxConcurrentSnapshot() -> Int {
        maxConcurrent
    }
}

private func parseStreamPublishResultForTest(_ json: String) throws -> StreamPublishResultSummary {
    let paths = testPaths()
    try ensureRuntimeDirectories(paths)
    let resultJson = paths.tmpDir.appendingPathComponent("result.json")
    try Data(json.utf8).write(to: resultJson)
    return parseStreamPublishResult(
        resultJsonPath: resultJson.path,
        processResult: StreamPublishProcessResult(stdout: "noisy stdout", stderr: "noisy stderr", exitCode: 0)
    )
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

private func attributedBodyFixture(text: String, extraStrings: [String]) -> Data {
    let joined = (extraStrings + [text]).joined(separator: "\u{0}")
    return Data(joined.utf8)
}

private func sqliteBlobLiteral(_ data: Data) -> String {
    "X'\(data.map { String(format: "%02x", $0) }.joined())'"
}

private func insertRepairMessages(db: URL) throws {
    try runSQLite(db, """
    INSERT INTO handle (ROWID, id, service)
    VALUES (1, '+15206099095', 'iMessage');
    INSERT INTO message (ROWID, guid, text, attributedBody, is_from_me, date, service, handle_id)
    VALUES
      (887, 'guid-887', NULL, \(sqliteBlobLiteral(attributedBodyFixture(text: "Small update before you implement.", extraStrings: ["streamtyped", "NSMutableAttributedString", "NSObject"]))), 0, 1000000000, 'iMessage', 1),
      (888, 'guid-888', NULL, \(sqliteBlobLiteral(attributedBodyFixture(text: "Did you ever take my prior prompts anywhere?", extraStrings: ["streamtyped", "NSAttributedString"]))), 0, 1000000001, 'iMessage', 1),
      (889, 'guid-889', NULL, \(sqliteBlobLiteral(attributedBodyFixture(text: "Hello?", extraStrings: ["streamtyped", "__kIMMessagePartAttributeName"]))), 0, 1000000002, 'iMessage', 1);
    """)
}

private func repairIncidentState() -> BridgeState {
    let original = MessageItem(
        rowId: 885,
        guid: "guid-885",
        text: "Please implement the Messages bridge side of the stream publisher.",
        handleId: "+15206099095",
        service: "iMessage",
        receivedAt: "2026-05-30T07:20:22.990Z",
        attachments: []
    )
    let batch = PendingBatch(
        handleId: "+15206099095",
        service: "iMessage",
        startedAt: "2026-05-30T07:20:22.990Z",
        deadlineAt: "2026-05-30T07:20:33.990Z",
        items: [original]
    )
    var state = defaultBridgeState()
    state.lastProcessedRowId = 885
    state.lastProcessedGuid = "guid-885"
    state.codexSession = CodexSessionState(sessionId: "thread-stale", startedAt: nil, lastPromptAt: nil, lastCompletedAt: nil, expiresAt: nil, lastErrorAt: nil)
    state.activeJob = ActiveJob(
        jobId: "stale-job",
        guid: "guid-885",
        rowId: 885,
        type: "promptBatch",
        receivedAt: "2026-05-30T07:20:34.732Z",
        promptPreview: original.text,
        recipient: "+15206099095",
        service: "iMessage",
        startedAt: "2026-05-30T07:20:34.732Z",
        lastProgressAt: nil,
        lastUserUpdateAt: nil,
        lastEventAt: "2026-05-30T07:27:05.270Z",
        codexPid: 999_999,
        codexSessionId: "thread-stale",
        codexTurnId: "turn-stale",
        outputPath: nil,
        sessionLogPath: nil,
        status: "running",
        lastObservedSummary: "Started bridge restart.",
        permissionRecoveryAttempts: 0,
        waitingForPermissionSince: nil,
        lastPermissionEventId: nil,
        recoverableBatch: batch
    )
    return state
}

private func writeAutomationToml(id: String, name: String, status: String, paths: RuntimePaths) throws {
    let dir = paths.codexAutomationsDir.appendingPathComponent(id)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let toml = """
    version = 1
    id = "\(id)"
    kind = "cron"
    name = "\(name)"
    prompt = "test"
    status = "\(status)"
    rrule = "FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=31;BYHOUR=23;BYMINUTE=59;BYSECOND=0"
    model = "gpt-test"
    execution_environment = "local"
    cwds = ["~"]
    created_at = 1778640000000
    updated_at = 1778640000000
    """
    try Data(toml.utf8).write(to: dir.appendingPathComponent("automation.toml"))
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

private func unwrap<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else { throw TestFailure(description: message) }
    return value
}

private func readJsonObject(_ path: String) throws -> [String: Any] {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw TestFailure(description: "Expected JSON object at \(path)")
    }
    return object
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

private final class ConcurrentErrorRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var descriptions: [String] = []

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return descriptions.isEmpty
    }

    func record(_ error: Error) {
        lock.lock()
        descriptions.append(String(describing: error))
        lock.unlock()
    }
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
