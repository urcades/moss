import Foundation

public enum BridgeConstants {
    public static let appName = "MessagesLLMBridge"
    public static let appBundleIdentifier = "com.moss.MessagesCodexBridge"
    public static let helperBundleIdentifier = "com.moss.MessagesCodexBridge.Helper"
    public static let permissionBrokerBundleIdentifier = "com.moss.MessagesCodexBridge.PermissionBroker"
    public static let helperLaunchAgentLabel = "com.moss.MessagesCodexBridge.Helper"
    public static let permissionBrokerLaunchAgentLabel = "com.moss.MessagesCodexBridge.PermissionBroker"
    public static let defaultAllowedSender = ""
    public static let defaultPollIntervalMs = 2_000
    public static let defaultBatchWindowMs = 11_000
    public static let defaultChunkSize = 1_200
    public static let defaultAckDelayMs = 0
    public static let defaultTimeoutMs = 15 * 60 * 1_000
    public static let defaultSessionTtlMs = 4 * 60 * 60 * 1_000
    public static let defaultLongTaskProgressIntervalMs = 120_000
    public static let defaultLongTaskMilestoneMinIntervalMs = 30_000
    public static let defaultPermissionBrokerScanIntervalMs = 500
    public static let defaultPermissionBrokerRecoveryTimeoutMs = 120_000
    public static let defaultPermissionBrokerMaxRecoveryAttempts = 3
    public static let defaultActiveJobAckText = "I'm on it. I'll send updates here as I make progress."
    public static let localCommands: Set<String> = ["/status", "/cancel", "/reset", "/new", "/help", "/permissions", "/codex"]
    public static let baseBridgeInstructions = """
    You are replying through Apple Messages on a Mac.
    Apple Messages is a remote control surface for Codex running on this Mac.
    Return plain text only.
    Do not include ANSI color codes.
    Avoid heavy markdown, code fences, and tables unless the user explicitly asks for them.
    Treat requests to create, update, list, delete, watch, monitor, remind, follow up, or otherwise schedule automations as requests to use Codex automation tools when those tools are available.
    If Codex automation tools are unavailable, say that clearly; do not implement a replacement inside the Messages bridge unless the user explicitly asks you to change the bridge.
    Treat requests that name plugins, skills, apps, or tools as requests to invoke the relevant Codex capability when available.
    Do not modify the Messages bridge itself unless the user explicitly asks to change the bridge.
    When you create or save an image, screenshot, PDF, document, archive, or other file artifact that should be sent to the user, include a separate line `BRIDGE_ATTACH: /absolute/path/to/file`.
    Output only the text that should be sent back as the message reply.
    """
    public static let defaultStylePrompt = """
    Be warm, natural, and conversational.
    Sound like a thoughtful assistant texting in Messages, not a terse terminal tool.
    Be helpful and a little more personable, while still staying clear and practical.
    Keep replies readable in Messages with short paragraphs and minimal formatting.
    """
}

public struct CodexConfig: Codable, Equatable, Sendable {
    public var command: String
    public var cwd: String
    public var model: String?
    public var reasoningEffort: String?
    public var stylePrompt: String?
    public var extraArgs: [String]
}

public struct BridgeConfig: Codable, Equatable, Sendable {
    public var allowedSender: String
    public var trustedSenders: [String]?
    public var pollIntervalMs: Int
    public var batchWindowMs: Int
    public var chunkSize: Int
    public var ackDelayMs: Int
    public var timeoutMs: Int
    public var sessionTtlMs: Int
    public var homeAccessRoot: String
    public var messagesDbPath: String
    public var osascriptCommand: String
    public var codex: CodexConfig
    public var outgoingAttachmentMode: String?
    public var outgoingAttachmentRoots: [String]?
    public var outgoingAttachmentExtensions: [String]?
    public var longTaskProgressIntervalMs: Int?
    public var longTaskMilestoneMinIntervalMs: Int?
    public var activeJobAckEnabled: Bool?
    public var activeJobAckText: String?
    public var permissionBroker: PermissionBrokerConfig?
}

public struct PermissionBrokerConfig: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var mode: String
    public var scanIntervalMs: Int
    public var recoveryTimeoutMs: Int
    public var maxRecoveryAttempts: Int
    public var trustedRequesters: [String]
    public var trustedPromptOwners: [String]
    public var positiveButtonLabels: [String]
    public var ignoredButtonLabels: [String]

    public init(
        enabled: Bool,
        mode: String,
        scanIntervalMs: Int,
        recoveryTimeoutMs: Int,
        maxRecoveryAttempts: Int,
        trustedRequesters: [String],
        trustedPromptOwners: [String],
        positiveButtonLabels: [String],
        ignoredButtonLabels: [String]
    ) {
        self.enabled = enabled
        self.mode = mode
        self.scanIntervalMs = scanIntervalMs
        self.recoveryTimeoutMs = recoveryTimeoutMs
        self.maxRecoveryAttempts = maxRecoveryAttempts
        self.trustedRequesters = trustedRequesters
        self.trustedPromptOwners = trustedPromptOwners
        self.positiveButtonLabels = positiveButtonLabels
        self.ignoredButtonLabels = ignoredButtonLabels
    }
}

public struct CodexSessionState: Codable, Equatable, Sendable {
    public var sessionId: String?
    public var startedAt: String?
    public var lastPromptAt: String?
    public var lastCompletedAt: String?
    public var expiresAt: String?
    public var lastErrorAt: String?

    public init(sessionId: String? = nil, startedAt: String? = nil, lastPromptAt: String? = nil, lastCompletedAt: String? = nil, expiresAt: String? = nil, lastErrorAt: String? = nil) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.lastPromptAt = lastPromptAt
        self.lastCompletedAt = lastCompletedAt
        self.expiresAt = expiresAt
        self.lastErrorAt = lastErrorAt
    }
}

public struct ActiveJob: Codable, Equatable, Sendable {
    public var jobId: String?
    public var guid: String?
    public var rowId: Int64?
    public var type: String
    public var receivedAt: String
    public var promptPreview: String
    public var recipient: String?
    public var service: String?
    public var startedAt: String?
    public var lastProgressAt: String?
    public var lastUserUpdateAt: String?
    public var lastEventAt: String?
    public var codexPid: Int32?
    public var codexSessionId: String?
    public var codexTurnId: String?
    public var outputPath: String?
    public var sessionLogPath: String?
    public var status: String?
    public var lastObservedSummary: String?
    public var permissionRecoveryAttempts: Int?
    public var waitingForPermissionSince: String?
    public var lastPermissionEventId: String?

    public init(
        jobId: String?,
        guid: String?,
        rowId: Int64?,
        type: String,
        receivedAt: String,
        promptPreview: String,
        recipient: String?,
        service: String?,
        startedAt: String?,
        lastProgressAt: String?,
        lastUserUpdateAt: String?,
        lastEventAt: String?,
        codexPid: Int32?,
        codexSessionId: String?,
        codexTurnId: String? = nil,
        outputPath: String?,
        sessionLogPath: String?,
        status: String?,
        lastObservedSummary: String?,
        permissionRecoveryAttempts: Int?,
        waitingForPermissionSince: String?,
        lastPermissionEventId: String?
    ) {
        self.jobId = jobId
        self.guid = guid
        self.rowId = rowId
        self.type = type
        self.receivedAt = receivedAt
        self.promptPreview = promptPreview
        self.recipient = recipient
        self.service = service
        self.startedAt = startedAt
        self.lastProgressAt = lastProgressAt
        self.lastUserUpdateAt = lastUserUpdateAt
        self.lastEventAt = lastEventAt
        self.codexPid = codexPid
        self.codexSessionId = codexSessionId
        self.codexTurnId = codexTurnId
        self.outputPath = outputPath
        self.sessionLogPath = sessionLogPath
        self.status = status
        self.lastObservedSummary = lastObservedSummary
        self.permissionRecoveryAttempts = permissionRecoveryAttempts
        self.waitingForPermissionSince = waitingForPermissionSince
        self.lastPermissionEventId = lastPermissionEventId
    }
}

public struct PermissionBrokerStatus: Codable, Equatable, Sendable {
    public var running: Bool
    public var accessibilityTrusted: Bool
    public var mode: String
    public var lastScanAt: String?
    public var lastActionAt: String?
    public var lastEventId: String?
    public var lastSummary: String?
    public var processId: Int32?

    public init(running: Bool, accessibilityTrusted: Bool, mode: String, lastScanAt: String?, lastActionAt: String?, lastEventId: String?, lastSummary: String?, processId: Int32?) {
        self.running = running
        self.accessibilityTrusted = accessibilityTrusted
        self.mode = mode
        self.lastScanAt = lastScanAt
        self.lastActionAt = lastActionAt
        self.lastEventId = lastEventId
        self.lastSummary = lastSummary
        self.processId = processId
    }
}

public struct PermissionBrokerEvent: Codable, Equatable, Sendable {
    public var eventId: String
    public var timestamp: String
    public var kind: String
    public var ownerName: String
    public var ownerBundleId: String?
    public var windowTitle: String
    public var promptText: String
    public var buttonLabel: String?
    public var requesterMatched: String?
    public var actionResult: String
    public var activeJobId: String?

    public init(
        eventId: String = UUID().uuidString,
        timestamp: String = DateCodec.iso(),
        kind: String,
        ownerName: String,
        ownerBundleId: String?,
        windowTitle: String,
        promptText: String,
        buttonLabel: String?,
        requesterMatched: String?,
        actionResult: String,
        activeJobId: String?
    ) {
        self.eventId = eventId
        self.timestamp = timestamp
        self.kind = kind
        self.ownerName = ownerName
        self.ownerBundleId = ownerBundleId
        self.windowTitle = windowTitle
        self.promptText = promptText
        self.buttonLabel = buttonLabel
        self.requesterMatched = requesterMatched
        self.actionResult = actionResult
        self.activeJobId = activeJobId
    }
}

public struct AttachmentRef: Codable, Equatable, Sendable {
    public var attachmentId: Int64
    public var transferName: String?
    public var mimeType: String?
    public var uti: String?
    public var absolutePath: String?
    public var kind: String
    public var exists: Bool

    public init(attachmentId: Int64, transferName: String?, mimeType: String?, uti: String?, absolutePath: String?, kind: String, exists: Bool) {
        self.attachmentId = attachmentId
        self.transferName = transferName
        self.mimeType = mimeType
        self.uti = uti
        self.absolutePath = absolutePath
        self.kind = kind
        self.exists = exists
    }
}

public struct MessageItem: Codable, Equatable, Sendable {
    public var rowId: Int64
    public var guid: String
    public var text: String
    public var handleId: String
    public var service: String
    public var receivedAt: String?
    public var attachments: [AttachmentRef]

    public init(rowId: Int64, guid: String, text: String, handleId: String, service: String, receivedAt: String?, attachments: [AttachmentRef]) {
        self.rowId = rowId
        self.guid = guid
        self.text = text
        self.handleId = handleId
        self.service = service
        self.receivedAt = receivedAt
        self.attachments = attachments
    }
}

public struct PendingBatch: Codable, Equatable, Sendable {
    public var handleId: String
    public var service: String
    public var startedAt: String
    public var deadlineAt: String
    public var items: [MessageItem]

    public init(handleId: String, service: String, startedAt: String, deadlineAt: String, items: [MessageItem]) {
        self.handleId = handleId
        self.service = service
        self.startedAt = startedAt
        self.deadlineAt = deadlineAt
        self.items = items
    }
}

public struct CodexAutomationRoute: Codable, Equatable, Sendable {
    public var automationId: String
    public var name: String
    public var recipient: String
    public var service: String
    public var createdFromGuid: String?
    public var createdFromRowId: Int64?
    public var createdAt: String
    public var lastSeenSessionId: String?
    public var lastDeliveredSessionId: String?
    public var lastDeliveredAt: String?

    public init(
        automationId: String,
        name: String,
        recipient: String,
        service: String,
        createdFromGuid: String?,
        createdFromRowId: Int64?,
        createdAt: String,
        lastSeenSessionId: String? = nil,
        lastDeliveredSessionId: String? = nil,
        lastDeliveredAt: String? = nil
    ) {
        self.automationId = automationId
        self.name = name
        self.recipient = recipient
        self.service = service
        self.createdFromGuid = createdFromGuid
        self.createdFromRowId = createdFromRowId
        self.createdAt = createdAt
        self.lastSeenSessionId = lastSeenSessionId
        self.lastDeliveredSessionId = lastDeliveredSessionId
        self.lastDeliveredAt = lastDeliveredAt
    }
}

public struct OutboundDeliveryEvidence: Codable, Equatable, Sendable {
    public var transport: String
    public var dbRowId: Int64?
    public var dbError: Int?
    public var transferState: Int?
    public var dateDelivered: Int64?
    public var detail: String?

    public init(transport: String, dbRowId: Int64? = nil, dbError: Int? = nil, transferState: Int? = nil, dateDelivered: Int64? = nil, detail: String? = nil) {
        self.transport = transport
        self.dbRowId = dbRowId
        self.dbError = dbError
        self.transferState = transferState
        self.dateDelivered = dateDelivered
        self.detail = detail
    }
}

public struct OutboundSendRecord: Codable, Equatable, Sendable {
    public var attemptId: String
    public var kind: String
    public var recipient: String
    public var service: String
    public var artifact: String?
    public var body: String?
    public var status: String
    public var startedAt: String
    public var completedAt: String?
    public var retryable: Bool
    public var evidence: OutboundDeliveryEvidence?
    public var error: String?

    public init(
        attemptId: String,
        kind: String,
        recipient: String,
        service: String,
        artifact: String?,
        body: String? = nil,
        status: String,
        startedAt: String,
        completedAt: String? = nil,
        retryable: Bool = false,
        evidence: OutboundDeliveryEvidence? = nil,
        error: String? = nil
    ) {
        self.attemptId = attemptId
        self.kind = kind
        self.recipient = recipient
        self.service = service
        self.artifact = artifact
        self.body = body
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.retryable = retryable
        self.evidence = evidence
        self.error = error
    }
}

public struct RecentMediaRef: Codable, Equatable, Sendable {
    public var direction: String
    public var rowId: Int64?
    public var handleId: String
    public var service: String
    public var path: String
    public var transferName: String?
    public var kind: String
    public var createdAt: String
    public var exists: Bool

    public init(direction: String, rowId: Int64? = nil, handleId: String, service: String, path: String, transferName: String? = nil, kind: String, createdAt: String, exists: Bool) {
        self.direction = direction
        self.rowId = rowId
        self.handleId = handleId
        self.service = service
        self.path = path
        self.transferName = transferName
        self.kind = kind
        self.createdAt = createdAt
        self.exists = exists
    }
}

public struct LiveSmokeResult: Codable, Equatable, Sendable {
    public var name: String
    public var marker: String
    public var status: String
    public var detail: String
    public var threadId: String?
    public var turnId: String?
    public var updatedAt: String

    public init(name: String, marker: String, status: String, detail: String, threadId: String? = nil, turnId: String? = nil, updatedAt: String) {
        self.name = name
        self.marker = marker
        self.status = status
        self.detail = detail
        self.threadId = threadId
        self.turnId = turnId
        self.updatedAt = updatedAt
    }
}

public struct AutomationCreationStatus: Codable, Equatable, Sendable {
    public var automationId: String?
    public var name: String?
    public var sourceRowId: Int64?
    public var sourceGuid: String?
    public var phase: String
    public var createdFilePath: String?
    public var routeStatus: String?
    public var confirmationSendStatus: String?
    public var failureText: String?
    public var updatedAt: String

    public init(automationId: String? = nil, name: String? = nil, sourceRowId: Int64? = nil, sourceGuid: String? = nil, phase: String, createdFilePath: String? = nil, routeStatus: String? = nil, confirmationSendStatus: String? = nil, failureText: String? = nil, updatedAt: String) {
        self.automationId = automationId
        self.name = name
        self.sourceRowId = sourceRowId
        self.sourceGuid = sourceGuid
        self.phase = phase
        self.createdFilePath = createdFilePath
        self.routeStatus = routeStatus
        self.confirmationSendStatus = confirmationSendStatus
        self.failureText = failureText
        self.updatedAt = updatedAt
    }
}

public struct PendingInteractiveCallback: Codable, Equatable, Sendable {
    public var callbackId: String
    public var jobId: String?
    public var jsonRpcId: String?
    public var method: String
    public var recipient: String
    public var service: String
    public var prompt: String
    public var createdAt: String
    public var expiresAt: String?
    public var status: String
    public var failureText: String?
    public var responseText: String?
    public var responseRowId: Int64?
    public var responseGuid: String?
    public var answeredAt: String?

    public init(callbackId: String, jobId: String? = nil, jsonRpcId: String? = nil, method: String, recipient: String, service: String, prompt: String, createdAt: String, expiresAt: String? = nil, status: String, failureText: String? = nil, responseText: String? = nil, responseRowId: Int64? = nil, responseGuid: String? = nil, answeredAt: String? = nil) {
        self.callbackId = callbackId
        self.jobId = jobId
        self.jsonRpcId = jsonRpcId
        self.method = method
        self.recipient = recipient
        self.service = service
        self.prompt = prompt
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.status = status
        self.failureText = failureText
        self.responseText = responseText
        self.responseRowId = responseRowId
        self.responseGuid = responseGuid
        self.answeredAt = answeredAt
    }
}

public struct BridgeState: Codable, Equatable, Sendable {
    public var lastProcessedGuid: String?
    public var lastProcessedRowId: Int64
    public var pendingBatch: PendingBatch?
    public var activeJob: ActiveJob?
    public var codexSession: CodexSessionState
    public var automationRoutes: [CodexAutomationRoute]?
    public var lastOutboundSend: OutboundSendRecord?
    public var recentMediaRefs: [RecentMediaRef]?
    public var liveSmokeResults: [LiveSmokeResult]?
    public var automationCreationStatus: AutomationCreationStatus?
    public var pendingInteractiveCallback: PendingInteractiveCallback?

    public init(lastProcessedGuid: String?, lastProcessedRowId: Int64, pendingBatch: PendingBatch?, activeJob: ActiveJob?, codexSession: CodexSessionState, automationRoutes: [CodexAutomationRoute]? = nil, lastOutboundSend: OutboundSendRecord? = nil, recentMediaRefs: [RecentMediaRef]? = nil, liveSmokeResults: [LiveSmokeResult]? = nil, automationCreationStatus: AutomationCreationStatus? = nil, pendingInteractiveCallback: PendingInteractiveCallback? = nil) {
        self.lastProcessedGuid = lastProcessedGuid
        self.lastProcessedRowId = lastProcessedRowId
        self.pendingBatch = pendingBatch
        self.activeJob = activeJob
        self.codexSession = codexSession
        self.automationRoutes = automationRoutes
        self.lastOutboundSend = lastOutboundSend
        self.recentMediaRefs = recentMediaRefs
        self.liveSmokeResults = liveSmokeResults
        self.automationCreationStatus = automationCreationStatus
        self.pendingInteractiveCallback = pendingInteractiveCallback
    }
}

public struct PromptRequest: Equatable, Sendable {
    public var promptText: String
    public var attachments: [AttachmentRef]
    public var threadName: String?

    public init(promptText: String, attachments: [AttachmentRef], threadName: String? = nil) {
        self.promptText = promptText
        self.attachments = attachments
        self.threadName = threadName
    }
}

public struct CodexMentionRef: Codable, Equatable, Sendable {
    public var name: String
    public var path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

public struct CodexResponse: Equatable, Sendable {
    public var text: String
    public var sessionId: String?
    public var stdout: String
    public var stderr: String
    public var args: [String]
    public var outputPath: String

    public init(text: String, sessionId: String?, stdout: String, stderr: String, args: [String], outputPath: String) {
        self.text = text
        self.sessionId = sessionId
        self.stdout = stdout
        self.stderr = stderr
        self.args = args
        self.outputPath = outputPath
    }
}
