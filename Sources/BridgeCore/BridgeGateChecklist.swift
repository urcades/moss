import Foundation

public struct BridgeGateChecklistContext: Equatable, Sendable {
    public var allowedSender: String
    public var service: String
    public var hasActiveJob: Bool
    public var hasPendingInteractiveCallback: Bool
    public var hasRecentInboundImage: Bool
    public var hasRecentOutboundImage: Bool

    public init(
        allowedSender: String,
        service: String = "iMessage",
        hasActiveJob: Bool,
        hasPendingInteractiveCallback: Bool,
        hasRecentInboundImage: Bool,
        hasRecentOutboundImage: Bool
    ) {
        self.allowedSender = allowedSender
        self.service = service
        self.hasActiveJob = hasActiveJob
        self.hasPendingInteractiveCallback = hasPendingInteractiveCallback
        self.hasRecentInboundImage = hasRecentInboundImage
        self.hasRecentOutboundImage = hasRecentOutboundImage
    }
}

public func bridgeGateChecklistText(context: BridgeGateChecklistContext) -> String {
    let recipientSuffix = context.allowedSender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : " --recipient \(context.allowedSender)"
    let serviceSuffix = " --service \(context.service)"
    let liveSuffix = recipientSuffix + serviceSuffix
    let activeStatus = context.hasActiveJob ? "blocked until active job clears or /cancel runs" : "ready"
    let callbackStatus = context.hasPendingInteractiveCallback ? "blocked until pending callback completes, expires, or /cancel runs" : "ready"
    let inboundStatus = context.hasRecentInboundImage ? "ready" : "needs trusted inbound image first"
    let outboundStatus = context.hasRecentOutboundImage ? "ready" : "will create a marked outbound image"
    return """
    Apple Messages Bridge gate checklist

    Current readiness:
    - Active job: \(activeStatus)
    - Pending callback: \(callbackStatus)
    - Inbound-image smoke: \(inboundStatus)
    - Outbound-image smoke: \(outboundStatus)

    Deterministic local gates:
    - swift run BridgeCoreTests
    - swift run BridgeCoreSelfTest
    - swift test
    - swift run codexmsgctl-swift doctor --probe-computer-use
    - swift run codexmsgctl-swift trusted-gates

    Live CLI gates:
    - swift run codexmsgctl-swift smoke text\(liveSuffix)
    - swift run codexmsgctl-swift smoke attachment\(liveSuffix)
    - swift run codexmsgctl-swift smoke bridge-attach\(liveSuffix)
    - swift run codexmsgctl-swift smoke generated-image\(liveSuffix)
    - swift run codexmsgctl-swift smoke app-server
    - swift run codexmsgctl-swift smoke inbound-image-check\(liveSuffix)
    - swift run codexmsgctl-swift smoke outbound-image-check\(liveSuffix)
    - swift run codexmsgctl-swift smoke chrome
    - swift run codexmsgctl-swift smoke browser
    - swift run codexmsgctl-swift smoke computer-use
    - swift run codexmsgctl-swift smoke automation\(liveSuffix)

    Trusted Messages gates:
    - /codex status
    - /codex gates
    - /codex smoke text
    - /codex smoke attachment
    - /codex smoke bridge-attach
    - /codex smoke generated-image
    - /codex smoke app-server
    - /codex smoke inbound-image-check
    - /codex smoke outbound-image-check
    - /codex smoke chrome
    - /codex smoke browser
    - /codex smoke computer-use
    - /codex smoke automation
    - /codex smoke callback, then reply with any short text
    - /codex smoke app-server-callback, then reply to the app-server prompt

    Trusted evidence observer:
    - /codex trusted-gates

    Open proof gaps:
    - Live trusted-chat evidence for `/codex smoke app-server-callback`.
    - Live trusted-chat evidence for `/codex smoke generated-image` and a follow-up edit probe.
    """
}
