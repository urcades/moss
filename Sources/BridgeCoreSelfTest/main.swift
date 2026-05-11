import BridgeCore
import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw SelfTestError(message)
    }
}

struct SelfTestError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description = description }
}

func testSQLiteMessageSourceTrustedSenders() async throws {
    let dbURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("messages-bridge-trusted-senders-\(UUID().uuidString).sqlite")
    defer { try? FileManager.default.removeItem(at: dbURL) }
    let sql = """
    CREATE TABLE handle(ROWID INTEGER PRIMARY KEY, id TEXT, service TEXT);
    CREATE TABLE message(ROWID INTEGER PRIMARY KEY, guid TEXT, text TEXT, date INTEGER, handle_id INTEGER, is_from_me INTEGER, service TEXT);
    CREATE TABLE message_attachment_join(message_id INTEGER, attachment_id INTEGER);
    CREATE TABLE attachment(ROWID INTEGER PRIMARY KEY, filename TEXT, mime_type TEXT, uti TEXT, transfer_name TEXT);
    INSERT INTO handle(ROWID, id, service) VALUES (1, '+1 (520) 609-9095', 'iMessage');
    INSERT INTO handle(ROWID, id, service) VALUES (2, 'Moss@Example.COM', 'iMessage');
    INSERT INTO handle(ROWID, id, service) VALUES (3, '+1 999 000 0000', 'iMessage');
    INSERT INTO message(ROWID, guid, text, date, handle_id, is_from_me, service) VALUES (1, 'phone', 'phone prompt', 1000000000, 1, 0, 'iMessage');
    INSERT INTO message(ROWID, guid, text, date, handle_id, is_from_me, service) VALUES (2, 'email', 'email prompt', 1000000000, 2, 0, 'iMessage');
    INSERT INTO message(ROWID, guid, text, date, handle_id, is_from_me, service) VALUES (3, 'other', 'other prompt', 1000000000, 3, 0, 'iMessage');
    """
    _ = try await ProcessRunner().run("/usr/bin/sqlite3", [dbURL.path, sql])
    let source = SQLiteMessageSource(dbPath: dbURL.path, trustedSenders: ["5206099095", "moss@example.com"])
    let messages = try await source.fetchNewMessages(afterRowId: 0)
    try expect(messages.map(\.guid) == ["phone", "email"], "SQLite source matches multiple trusted senders")
    let emptySource = SQLiteMessageSource(dbPath: dbURL.path, trustedSenders: [])
    let emptyMessages = try await emptySource.fetchNewMessages(afterRowId: 0)
    try expect(emptyMessages == [], "SQLite source ignores all messages with no trusted senders")
}

@main
struct BridgeCoreSelfTest {
    static func main() async throws {
        try expect(senderAliases("+1 (520) 609-9095") == ["15206099095", "5206099095"], "sender aliases for +1 format")
        try expect(senderAliases("5206099095") == ["5206099095", "15206099095"], "sender aliases for ten digits")
        try expect(normalizedTrustedSenderIdentity("+1 (520) 609-9095") == "15206099095", "trusted sender phone identity")
        try expect(normalizedTrustedSenderIdentity("User@Example.COM") == "user@example.com", "trusted sender email identity")
        try expect(normalizedTrustedSenderList([" +1 (520) 609-9095 ", "15206099095", "User@Example.COM", "user@example.com"]) == ["+1 (520) 609-9095", "User@Example.COM"], "trusted sender list trims and de-duplicates")
        try expect(appleTimestampToISO("0") == nil, "zero Apple timestamp is nil")
        try expect(appleTimestampToISO("1000000000")?.hasPrefix("2001-01-01T00:00:01") == true, "Apple timestamp conversion")
        try expect(classifyAttachment(mimeType: "image/png", uti: nil, absolutePath: nil) == "image", "image MIME classification")
        try expect(classifyAttachment(mimeType: nil, uti: "com.adobe.pdf", absolutePath: nil) == "pdf", "PDF UTI classification")
        try expect(classifyAttachment(mimeType: "text/plain", uti: nil, absolutePath: "/tmp/a.txt") == "unsupported", "unsupported attachment classification")

        let paths = RuntimePaths.current(projectRoot: URL(fileURLWithPath: "/tmp/MessagesCodexBridgeMac"))
        let diagnostics = runtimeDiagnosticChecks(paths: paths)
        try expect(diagnostics.contains { $0.name == "Installed runtime app path" }, "doctor diagnostics include installed app path")
        try expect(diagnostics.contains { $0.name == "Installed app signing" }, "doctor diagnostics include signing summary")
        var config = defaultBridgeConfig(paths: paths)
        try expect(config.allowedSender.isEmpty, "fresh default has no personal allowed sender")
        try expect(config.effectiveTrustedSenders.isEmpty, "fresh default has no trusted senders")
        try expect(config.effectiveOutgoingAttachmentMode == "restricted", "fresh default restricts outgoing attachments")
        try expect(config.effectiveOutgoingAttachmentRoots == defaultOutgoingAttachmentRoots(homeAccessRoot: paths.homeDir.path), "fresh default uses home and temp attachment roots")
        try expect(config.effectiveOutgoingAttachmentExtensions == defaultOutgoingAttachmentExtensions(), "fresh default uses image and PDF attachment extensions")
        try expect(!config.effectivePermissionBroker.enabled, "fresh default leaves broker auto-clicking off")
        var legacyConfig = config
        legacyConfig.allowedSender = "+1 (520) 609-9095"
        legacyConfig.trustedSenders = nil
        migrateTrustedSenders(&legacyConfig)
        try expect(legacyConfig.trustedSenders == ["+1 (520) 609-9095"], "legacy allowed sender migrates into trusted senders")
        try expect(legacyConfig.allowedSender == "+1 (520) 609-9095", "legacy allowed sender remains synced")
        var multiSenderConfig = config
        multiSenderConfig.syncTrustedSenders(["+1 (520) 609-9095", "Moss@Example.COM", "15206099095"])
        try expect(multiSenderConfig.trustedSenders == ["+1 (520) 609-9095", "Moss@Example.COM"], "multi sender config de-duplicates")
        try expect(multiSenderConfig.allowedSender == "+1 (520) 609-9095", "allowed sender syncs to first trusted sender")
        var standardConfig = multiSenderConfig
        applySafetyProfile(.standard, to: &standardConfig)
        try expect(standardConfig.trustedSenders == multiSenderConfig.trustedSenders, "standard safety preserves trusted senders")
        try expect(standardConfig.effectiveOutgoingAttachmentMode == "restricted", "standard safety uses restricted attachments")
        try expect(!standardConfig.effectivePermissionBroker.enabled, "standard safety disables broker auto-clicking")
        var permissiveConfig = multiSenderConfig
        applySafetyProfile(.permissive, to: &permissiveConfig)
        try expect(permissiveConfig.trustedSenders == multiSenderConfig.trustedSenders, "permissive safety preserves trusted senders")
        try expect(permissiveConfig.effectiveOutgoingAttachmentMode == "fullAccess", "permissive safety uses full attachment access")
        try expect(permissiveConfig.effectiveOutgoingAttachmentRoots == ["/"], "permissive safety uses root attachment access")
        try expect(permissiveConfig.effectiveOutgoingAttachmentExtensions == ["*"], "permissive safety allows all attachment extensions")
        try expect(permissiveConfig.effectivePermissionBroker.enabled, "permissive safety enables broker auto-clicking")
        var preservedConfig = permissiveConfig
        applySafetyProfile(.preserve, to: &preservedConfig)
        try expect(preservedConfig == permissiveConfig, "preserve safety leaves existing safety fields untouched")
        config.codex.command = "/bin/echo"
        config.codex.model = "gpt-5.5"
        config.codex.reasoningEffort = "low"
        let launchAgentData = try helperLaunchAgentPlistData(paths: paths, helperExecutable: URL(fileURLWithPath: "/bin/echo"))
        let launchAgent = try PropertyListSerialization.propertyList(from: launchAgentData, options: [], format: nil) as? [String: Any]
        try expect(launchAgent?["Label"] as? String == BridgeConstants.helperLaunchAgentLabel, "helper launch agent label")
        try expect((launchAgent?["ProgramArguments"] as? [String]) == ["/bin/echo"], "helper launch agent executable")
        try expect(launchAgent?["RunAtLoad"] as? Bool == true, "helper launch agent run at load")
        let brokerLaunchAgentData = try permissionBrokerLaunchAgentPlistData(paths: paths, brokerExecutable: URL(fileURLWithPath: "/bin/echo"))
        let brokerLaunchAgent = try PropertyListSerialization.propertyList(from: brokerLaunchAgentData, options: [], format: nil) as? [String: Any]
        try expect(brokerLaunchAgent?["Label"] as? String == BridgeConstants.permissionBrokerLaunchAgentLabel, "permission broker launch agent label")
        try expect((brokerLaunchAgent?["ProgramArguments"] as? [String]) == ["/bin/echo"], "permission broker launch agent executable")
        let trustedPrompt = PermissionPromptSnapshot(
            ownerName: "SecurityAgent",
            ownerBundleId: "com.apple.SecurityAgent",
            windowTitle: "Contacts",
            promptText: "\"Codex\" would like to access your contacts.",
            buttonLabels: ["Don’t Allow", "Allow"]
        )
        let decision = permissionBrokerDecision(for: trustedPrompt, config: config.effectivePermissionBroker)
        try expect(!decision.shouldClick, "standard permission broker does not auto-allow trusted prompt")
        let permissiveDecision = permissionBrokerDecision(for: trustedPrompt, config: permissiveConfig.effectivePermissionBroker)
        try expect(permissiveDecision.shouldClick && permissiveDecision.buttonLabel == "Allow", "permissive permission broker auto-allows trusted prompt")
        let unknownPrompt = PermissionPromptSnapshot(
            ownerName: "SecurityAgent",
            ownerBundleId: "com.apple.SecurityAgent",
            windowTitle: "Contacts",
            promptText: "\"Unknown App\" would like to access your contacts.",
            buttonLabels: ["Don’t Allow", "Allow"]
        )
        try expect(!permissionBrokerDecision(for: unknownPrompt, config: config.effectivePermissionBroker).shouldClick, "permission broker ignores unknown requester")
        try expect(isRecoverablePermissionBlock("Apple event error -1743: Unknown error"), "recoverable TCC blocker")
        try expect(permissionBlock(in: "Apple event error -10005: cgWindowNotFound")?.contains("cgWindowNotFound") == true, "Computer Use window lookup blocker")
        try expect(permissionBlock(in: "Could not create a session: You must enable 'Allow remote automation' in Safari Settings") != nil, "Safari remote automation blocker")
        try expect(codexThreadDeepLink("thread-1") == "codex://threads/thread-1", "codex thread deep link")
        try expect(bridgeLocalCommandName("/codex status") == "/codex", "exact codex status command")
        try expect(bridgeLocalCommandName("  /codex open  ") == "/codex", "exact codex open command with whitespace")
        try expect(bridgeLocalCommandName("/codex history") == "/codex", "exact codex history command")
        try expect(bridgeLocalCommandName("/codex status please") == nil, "non-exact codex command is normal prompt text")
        try expect(bridgeLocalCommandName("what does /codex status show?") == nil, "natural language mentioning codex command is normal prompt text")
        try expect(bridgeLocalCommandName("/status please") == "/status", "existing local commands can still accept arguments")
        let capabilityLines = formatCodexCapabilityLines(CodexCapabilities(
            version: "0.130.0",
            appServerAvailable: true,
            remoteControlAvailable: true,
            threadReadAvailable: true,
            warnings: []
        ))
        try expect(capabilityLines.contains("Enhanced bridge UX: yes"), "codex capability formatter")
        let parser = CodexStreamParser()
        let echoedPrompt = #"{"type":"event_msg","payload":{"type":"user_message","message":"What does Apple event error -10005: cgWindowNotFound mean?"}}"#
        try expect(codexAutomationBlock(in: echoedPrompt) == nil, "streaming blocker ignores echoed user prompts")
        try expect(parser.consume(echoedPrompt + "\n", stream: .stdout).isEmpty, "stream parser ignores echoed user prompts")
        let toolBlock = #"{"type":"response_item","payload":{"type":"function_call_output","output":"Wall time: 0.0453 seconds\nOutput:\n[{\"type\":\"text\",\"text\":\"Apple event error -10005: cgWindowNotFound\"}]"}}"#
        try expect(codexAutomationBlock(in: toolBlock)?.contains("cgWindowNotFound") == true, "streaming blocker detects tool output")
        let transientClickFailure = #"{"type":"item.completed","item":{"id":"item_25","type":"mcp_tool_call","server":"computer-use","tool":"click","arguments":{"app":"Messages","element_index":"11"},"result":{"content":[{"type":"text","text":"Apple event error -10005: 11 is an invalid element ID"}],"structured_content":null},"error":null,"status":"failed"}}"# + "\n"
        try expect(codexAutomationBlock(in: transientClickFailure) == nil, "transient Computer Use click failure is not a blocker")
        try expect(parser.consume(transientClickFailure, stream: .stdout).isEmpty, "transient Computer Use click failure is not sent to Messages")
        let itemCompletedBlock = #"{"type":"item.completed","item":{"id":"item_26","type":"mcp_tool_call","server":"computer-use","tool":"get_app_state","result":{"content":[{"type":"text","text":"Apple event error -1743: Unknown error"}]},"status":"failed"}}"# + "\n"
        try expect(parser.consume(itemCompletedBlock, stream: .stdout).contains(.blocker("Apple event error -1743: Unknown error")), "structured Computer Use blocker extracts only blocker text")
        let sessionDumpCommand = #"{"type":"item.completed","item":{"id":"item_18","type":"command_execution","command":"/bin/zsh -lc \"grep -n base_instructions rollout.jsonl\"","aggregated_output":"1:{\"type\":\"session_meta\",\"payload\":{\"base_instructions\":{\"text\":\"You are Codex, a coding agent. Grant Accessibility to Codex.\"}}}\nMEMORY_SUMMARY BEGINS\n<permissions instructions>","status":"completed"}}"# + "\n"
        try expect(codexAutomationBlock(in: sessionDumpCommand) == nil, "command transcript dump is not treated as a blocker")
        try expect(parser.consume(sessionDumpCommand, stream: .stdout).isEmpty, "command transcript dump is not streamed to Messages")
        let malformedSessionDump = #"{"type":"item.completed","item":{"aggregated_output":"You are Codex, a coding agent. Grant Accessibility to Codex.""# + "\n"
        try expect(codexAutomationBlock(in: malformedSessionDump) == nil, "malformed internal JSON dump is ignored")
        try expect(parser.consume(malformedSessionDump, stream: .stdout).isEmpty, "malformed internal JSON dump is not streamed to Messages")
        try expect(safeUserVisibleText("hello\n\"base_instructions\": \"You are Codex, a coding agent\"") == internalBridgeLeakReplacement, "outbound guard suppresses internal transcript text")
        let memCitationReply = """
        Done with the thing.

        <oai-mem-citation>
        <citation_entries>
        MEMORY.md:1-2|note=[internal]
        </citation_entries>
        <rollout_ids>
        019dc27c-69ef-7c93-90dc-bfd0e1091e1e
        </rollout_ids>
        </oai-mem-citation>
        """
        try expect(safeUserVisibleText(memCitationReply) == "Done with the thing.", "outbound guard strips memory citation blocks")
        try expect(permissionBlock(in: "Please grant Accessibility to Codex so it can continue.") == nil, "generic grant wording is not a streaming blocker")
        try expect(markerEvents(in: "BRIDGE_PROGRESS: Still working.").contains(.progress("Still working.")), "bridge progress marker")
        try expect(markerEvents(in: "prefix BRIDGE_PROGRESS: ignored").isEmpty, "bridge marker must be line anchored")
        let sessionLine = #"{"type":"session_meta","payload":{"id":"session-1"}}"# + "\n"
        try expect(parser.consume(sessionLine, stream: .stdout).contains(.sessionStarted("session-1")), "codex stream session event")
        let threadLine = #"{"type":"thread.started","thread_id":"thread-1"}"# + "\n"
        try expect(parser.consume(threadLine, stream: .stdout).contains(.sessionStarted("thread-1")), "codex stream thread event")
        let progressLine = #"{"type":"event_msg","payload":{"type":"agent_message","message":"BRIDGE_PROGRESS: Still working in Safari."}}"# + "\n"
        try expect(parser.consume(progressLine, stream: .stdout).contains(.progress("Still working in Safari.")), "codex stream progress marker event")
        do {
            _ = try await ProcessRunner().run(
                "/bin/sh",
                ["-c", "printf 'Apple event error -10005: cgWindowNotFound\\n'; sleep 5"],
                timeoutMs: 5000,
                outputInspector: permissionBlock(in:)
            )
            throw SelfTestError("streaming blocker did not stop the process")
        } catch let error as ProcessRunnerError {
            switch error {
            case .blocked(let message, _):
                try expect(message.contains("cgWindowNotFound"), "streaming blocker preserves blocker text")
            default:
                throw SelfTestError("streaming blocker raised wrong error: \(error)")
            }
        }

        let batch = PendingBatch(
            handleId: "+15206099095",
            service: "iMessage",
            startedAt: "2026-05-06T00:00:00.000Z",
            deadlineAt: "2026-05-06T00:00:11.000Z",
            items: [
                MessageItem(rowId: 1, guid: "a", text: "first", handleId: "+1", service: "iMessage", receivedAt: nil, attachments: []),
                MessageItem(rowId: 2, guid: "b", text: "second", handleId: "+1", service: "iMessage", receivedAt: nil, attachments: [
                    AttachmentRef(attachmentId: 10, transferName: "image.png", mimeType: "image/png", uti: nil, absolutePath: "/tmp/image.png", kind: "image", exists: false)
                ])
            ]
        )
        let request = buildPromptRequest(from: batch)
        try expect(request.promptText.contains("Message 1:\nfirst"), "prompt contains first message")
        try expect(request.promptText.contains("Message 2:\nsecond"), "prompt contains second message")
        try expect(request.promptText.contains("Image attachments are passed in as Codex image inputs"), "prompt explains inbound attachment handling")
        try expect(request.attachments.count == 1, "prompt carries attachment")
        try expect(request.threadName == "first / second", "prompt carries thread title preview")
        let outgoingDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches/MessagesLLMBridgeSelfTest/with space")
        try FileManager.default.createDirectory(at: outgoingDir, withIntermediateDirectories: true)
        let outgoingImage = outgoingDir.appendingPathComponent("test image.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: outgoingImage)
        let markerReply = prepareOutgoingReply("Done\nBRIDGE_ATTACH: \(outgoingImage.path)", homeAccessRoot: NSHomeDirectory())
        try expect(markerReply.text == "Done", "attachment marker removed from outgoing text")
        try expect(markerReply.attachments == [outgoingImage.path], "attachment marker extracts image path")
        let tempImage = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("messages-bridge-temp-image.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: tempImage)
        let tempReply = prepareOutgoingReply("Done\nBRIDGE_ATTACH: \(tempImage.path)", homeAccessRoot: NSHomeDirectory())
        try expect(tempReply.attachments == [tempImage.standardizedFileURL.path], "attachment marker accepts temp image path")
        let fullAccessFile = URL(fileURLWithPath: "/var/tmp/messages-bridge-full-access-test.anything")
        try Data([0x41, 0x42, 0x43]).write(to: fullAccessFile)
        let fullAccessReply = prepareOutgoingReply(
            "Done\nBRIDGE_ATTACH: \(fullAccessFile.path)",
            homeAccessRoot: NSHomeDirectory(),
            attachmentMode: "fullAccess",
            attachmentRoots: [],
            attachmentExtensions: ["*"]
        )
        try expect(fullAccessReply.attachments == [fullAccessFile.path], "full access attachment mode accepts regular files outside default roots")
        let fullAccessMentionedReply = prepareOutgoingReply(
            "File saved here: \(fullAccessFile.path)",
            homeAccessRoot: NSHomeDirectory(),
            attachmentMode: "fullAccess",
            attachmentRoots: [],
            attachmentExtensions: ["*"]
        )
        try expect(fullAccessMentionedReply.attachments == [fullAccessFile.path], "full access attachment mode detects mentioned regular files outside default roots")
        let mentionedReply = prepareOutgoingReply("Screenshot saved here:\n\(outgoingImage.path)", homeAccessRoot: NSHomeDirectory())
        try expect(mentionedReply.attachments == [outgoingImage.path], "plain mentioned image path with spaces is attached")
        let attachmentScript = appleMessagesAttachmentScriptLines().joined(separator: "\n")
        try expect(attachmentScript.contains("as alias"), "attachment AppleScript coerces POSIX file to alias")
        try expect(attachmentScript.contains("send attachmentFile to targetChat"), "attachment AppleScript falls back to chat send")
        let clipboardScript = appleMessagesClipboardImageScriptLines().joined(separator: "\n")
        try expect(clipboardScript.contains("set serviceName to item 2 of argv"), "clipboard image fallback accepts service")
        try expect(clipboardScript.contains("open location \"sms:\" & recipientHandle"), "clipboard image fallback uses proven Messages compose URL")
        try expect(clipboardScript.contains("set the clipboard"), "clipboard image fallback sets clipboard")
        try expect(clipboardScript.contains("key code 36"), "clipboard image fallback presses return")
        var shortTimeoutConfig = config
        shortTimeoutConfig.timeoutMs = 900_000
        shortTimeoutConfig.sessionTtlMs = 7_200_000
        try expect(configForPrompt(shortTimeoutConfig, request: PromptRequest(promptText: "Can you check Safari?", attachments: [])).timeoutMs == 900_000, "ordinary prompt keeps short timeout")
        try expect(configForPrompt(shortTimeoutConfig, request: PromptRequest(promptText: "Use Computer Use to monitor this dashboard until the export is complete.", attachments: [])).timeoutMs == 7_200_000, "long task prompt uses session timeout")
        try await testSQLiteMessageSourceTrustedSenders()
        let statusHelpService = BridgeService(
            paths: paths,
            makeSource: { _ in SQLiteMessageSource(dbPath: "/tmp/fake.db", allowedSender: "+1") },
            makeReplySink: { _ in AppleMessagesReplySink(osascriptCommand: "/usr/bin/osascript", chunkSize: 1200, messagesDbPath: "/tmp/fake.db") },
            makeCodex: { CodexAppServerBackend(config: $0, paths: paths) }
        )
        try expect(statusHelpService.runLocalCommand("/help").contains("/codex history"), "help lists codex control commands")
        try expect(chunkMessageText("hello world", chunkSize: 20) == ["hello world"], "short chunking")
        try expect(chunkMessageText("hello world again", chunkSize: 8) == ["hello", "world", "again"], "word chunking")
        print("BridgeCoreSelfTest passed.")
    }
}
