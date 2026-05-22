import Foundation

public struct BridgeGateChecklistContext: Equatable, Sendable {
    public var allowedSender: String
    public var service: String
    public var hasActiveJob: Bool
    public var hasPendingInteractiveCallback: Bool
    public var hasRecentInboundImage: Bool
    public var hasRecentOutboundImage: Bool
    public var activeBridgeSmokeAutomations: [CodexAutomationFileSummary]
    public var liveSmokeResults: [LiveSmokeResult]

    public init(
        allowedSender: String,
        service: String = "iMessage",
        hasActiveJob: Bool,
        hasPendingInteractiveCallback: Bool,
        hasRecentInboundImage: Bool,
        hasRecentOutboundImage: Bool,
        activeBridgeSmokeAutomations: [CodexAutomationFileSummary] = [],
        liveSmokeResults: [LiveSmokeResult] = []
    ) {
        self.allowedSender = allowedSender
        self.service = service
        self.hasActiveJob = hasActiveJob
        self.hasPendingInteractiveCallback = hasPendingInteractiveCallback
        self.hasRecentInboundImage = hasRecentInboundImage
        self.hasRecentOutboundImage = hasRecentOutboundImage
        self.activeBridgeSmokeAutomations = activeBridgeSmokeAutomations
        self.liveSmokeResults = liveSmokeResults
    }
}

public struct BridgeGateStrictReport: Equatable, Sendable {
    public var ok: Bool
    public var text: String

    public init(ok: Bool, text: String) {
        self.ok = ok
        self.text = text
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
    - Bridge smoke automations: \(bridgeSmokeAutomationStatusText(context.activeBridgeSmokeAutomations))
    - Live smoke evidence: \(liveSmokeResultsStatusText(context.liveSmokeResults))

    Deterministic local gates:
    - swift run BridgeCoreTests
    - swift run BridgeCoreSelfTest
    - swift test
    - swift run codexmsgctl-swift doctor --probe-computer-use
    - swift run codexmsgctl-swift trusted-gates
    - swift run codexmsgctl-swift gates --strict

    Live CLI gates:
    - swift run codexmsgctl-swift smoke text\(liveSuffix)
    - swift run codexmsgctl-swift smoke attachment\(liveSuffix)
    - swift run codexmsgctl-swift smoke bridge-attach\(liveSuffix)
    - swift run codexmsgctl-swift smoke generated-image\(liveSuffix)
    - swift run codexmsgctl-swift smoke edit-image-check\(liveSuffix)
    - swift run codexmsgctl-swift smoke app-server
    - swift run codexmsgctl-swift smoke app-server-callback
    - swift run codexmsgctl-swift smoke mcp-elicitation-callback
    - swift run codexmsgctl-swift smoke inbound-image-check\(liveSuffix)
    - swift run codexmsgctl-swift smoke outbound-image-check\(liveSuffix)
    - swift run codexmsgctl-swift smoke chrome
    - swift run codexmsgctl-swift smoke browser
    - swift run codexmsgctl-swift smoke computer-use
    - swift run codexmsgctl-swift smoke automation\(liveSuffix)

    Cleanup commands:
    - swift run codexmsgctl-swift smoke automation --deactivate-active --dry-run
    - swift run codexmsgctl-swift smoke automation --deactivate-active

    Trusted Messages gates:
    - /codex status
    - /codex gates
    - /codex smoke text
    - /codex smoke attachment
    - /codex smoke bridge-attach
    - /codex smoke generated-image
    - /codex smoke edit-image-check
    - /codex smoke app-server
    - /codex smoke inbound-image-check
    - /codex smoke outbound-image-check
    - /codex smoke chrome
    - /codex smoke browser
    - /codex smoke computer-use
    - /codex smoke automation
    - /codex smoke callback, then reply with any short text
    - /codex smoke app-server-callback, then reply to the app-server prompt
    - /codex smoke mcp-elicitation-callback, then reply to the MCP elicitation prompt

    Trusted evidence observer:
    - /codex trusted-gates
    - swift run codexmsgctl-swift trusted-gates --runbook

    Open proof gaps:
    - Live trusted-chat evidence for `/codex smoke app-server-callback`.
    - Live CLI and trusted-chat evidence for `/codex smoke mcp-elicitation-callback`.
    - Live trusted-chat evidence for `/codex smoke generated-image` and `/codex smoke edit-image-check`.
    """
}

public func bridgeGateStrictReport(context: BridgeGateChecklistContext, trustedGateEvidence: [TrustedGateEvidence]) -> BridgeGateStrictReport {
    let trustedSummary = trustedGateSummaryText(trustedGateEvidence)
    let trustedOpen = trustedGateEvidence.contains { $0.status != "observed" }
    let liveFailures = context.liveSmokeResults
        .filter { strictLiveSmokeFailure($0) != nil }
        .sorted { lhs, rhs in
            if lhs.name == rhs.name { return lhs.marker < rhs.marker }
            return lhs.name < rhs.name
        }
    let acceptedCapabilityBlockers = context.liveSmokeResults
        .filter(isAcceptedCapabilityBlocker)
        .sorted { lhs, rhs in
            if lhs.name == rhs.name { return lhs.marker < rhs.marker }
            return lhs.name < rhs.name
        }
    var failures: [String] = []
    if context.hasActiveJob {
        failures.append("Active job is still running.")
    }
    if context.hasPendingInteractiveCallback {
        failures.append("Pending interactive callback is waiting.")
    }
    if trustedOpen {
        failures.append("Trusted Messages gates: \(trustedSummary)")
    }
    if !context.activeBridgeSmokeAutomations.isEmpty {
        failures.append("Bridge smoke automations: \(bridgeSmokeAutomationStatusText(context.activeBridgeSmokeAutomations))")
        failures.append("Bridge smoke automation cleanup: swift run codexmsgctl-swift smoke automation --deactivate-active --dry-run")
    }
    if !liveFailures.isEmpty {
        let detail = liveFailures.map(strictLiveSmokeSummary).joined(separator: "; ")
        failures.append("Live smoke blockers: \(detail)")
    }
    guard failures.isEmpty else {
        if !acceptedCapabilityBlockers.isEmpty {
            let accepted = acceptedCapabilityBlockers.map(strictLiveSmokeSummary).joined(separator: "; ")
            failures.append("Accepted live capability blockers: \(accepted)")
        }
        return BridgeGateStrictReport(ok: false, text: (["Strict gate check failed."] + failures).joined(separator: "\n"))
    }
    var lines = [
        "Strict gate check passed.",
        "Trusted Messages gates: \(trustedSummary)"
    ]
    if !acceptedCapabilityBlockers.isEmpty {
        let accepted = acceptedCapabilityBlockers.map(strictLiveSmokeSummary).joined(separator: "; ")
        lines.append("Accepted live capability blockers: \(accepted)")
    }
    return BridgeGateStrictReport(ok: true, text: lines.joined(separator: "\n"))
}

private func strictLiveSmokeFailure(_ result: LiveSmokeResult) -> LiveSmokeResult? {
    if result.status.lowercased() == "passed" {
        return nil
    }
    if isAcceptedCapabilityBlocker(result) {
        return nil
    }
    return result
}

private func isAcceptedCapabilityBlocker(_ result: LiveSmokeResult) -> Bool {
    guard result.status.lowercased() == "blocked",
          !result.marker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !result.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return false
    }
    let name = result.name.hasPrefix("messages-") ? String(result.name.dropFirst("messages-".count)) : result.name
    return [
        "browser",
        "chrome",
        "computer-use",
        "computer-use-doctor"
    ].contains(name)
}

private func strictLiveSmokeSummary(_ result: LiveSmokeResult) -> String {
    var parts = [
        result.name,
        result.status,
        result.marker
    ]
    let normalizedDetail = result.detail.hasPrefix(result.marker)
        ? result.detail.dropFirst(result.marker.count).trimmingCharacters(in: .whitespacesAndNewlines)
        : result.detail
    if !normalizedDetail.isEmpty {
        let detail = normalizedDetail.count > 160 ? String(normalizedDetail.prefix(160)) : normalizedDetail
        parts.append(detail)
    }
    return parts.joined(separator: " ")
}
