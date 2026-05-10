import Foundation

public enum BridgeConstants {
    public static let appName = "MessagesLLMBridge"
    public static let appBundleIdentifier = "com.moss.MessagesCodexBridge"
    public static let helperBundleIdentifier = "com.moss.MessagesCodexBridge.Helper"
    public static let permissionBrokerBundleIdentifier = "com.moss.MessagesCodexBridge.PermissionBroker"
    public static let helperLaunchAgentLabel = "com.moss.MessagesCodexBridge.Helper"
    public static let permissionBrokerLaunchAgentLabel = "com.moss.MessagesCodexBridge.PermissionBroker"
    public static let defaultAllowedSender = "+1-520-609-9095"
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
    Return plain text only.
    Do not include ANSI color codes.
    Avoid heavy markdown, code fences, and tables unless the user explicitly asks for them.
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

public struct BridgeState: Codable, Equatable, Sendable {
    public var lastProcessedGuid: String?
    public var lastProcessedRowId: Int64
    public var pendingBatch: PendingBatch?
    public var activeJob: ActiveJob?
    public var codexSession: CodexSessionState

    public init(lastProcessedGuid: String?, lastProcessedRowId: Int64, pendingBatch: PendingBatch?, activeJob: ActiveJob?, codexSession: CodexSessionState) {
        self.lastProcessedGuid = lastProcessedGuid
        self.lastProcessedRowId = lastProcessedRowId
        self.pendingBatch = pendingBatch
        self.activeJob = activeJob
        self.codexSession = codexSession
    }
}

public struct PromptRequest: Equatable, Sendable {
    public var promptText: String
    public var attachments: [AttachmentRef]

    public init(promptText: String, attachments: [AttachmentRef]) {
        self.promptText = promptText
        self.attachments = attachments
    }
}

public struct CodexResponse: Equatable, Sendable {
    public var text: String
    public var sessionId: String?
    public var stdout: String
    public var stderr: String
    public var args: [String]
    public var outputPath: String
}
