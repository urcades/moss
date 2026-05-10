import AppKit
import ApplicationServices
import BridgeCore
import Foundation

@main
struct MessagesCodexPermissionBroker {
    static func main() async {
        let paths = RuntimePaths.current()
        let stores = RuntimeStores(paths: paths)
        let config = ((try? stores.config.load()) ?? defaultBridgeConfig(paths: paths)).effectivePermissionBroker
        let broker = PermissionBroker(paths: paths, config: config)

        if CommandLine.arguments.contains("--dry-run-scan") {
            broker.scan(dryRun: true)
            return
        }
        if CommandLine.arguments.contains("--once") {
            broker.scan(dryRun: false)
            return
        }
        await broker.runForever()
    }
}

private final class PermissionBroker {
    private let paths: RuntimePaths
    private let config: PermissionBrokerConfig
    private var recentActions: [String: Date] = [:]

    init(paths: RuntimePaths, config: PermissionBrokerConfig) {
        self.paths = paths
        self.config = config
    }

    func runForever() async {
        while true {
            autoreleasepool {
                scan(dryRun: false)
            }
            try? await Task.sleep(nanoseconds: UInt64(max(config.scanIntervalMs, 100)) * 1_000_000)
        }
    }

    func scan(dryRun: Bool) {
        let trusted = AXIsProcessTrusted() || requestAccessibilityTrust()
        var status = PermissionBrokerStatus(
            running: true,
            accessibilityTrusted: trusted,
            mode: dryRun ? "dryRun" : config.mode,
            lastScanAt: DateCodec.iso(),
            lastActionAt: nil,
            lastEventId: nil,
            lastSummary: trusted ? "Scanning." : "Accessibility is not granted to Messages Codex Permission Broker.",
            processId: getpid()
        )
        guard trusted else {
            try? writePermissionBrokerStatus(status, paths: paths)
            return
        }

        let candidates = collectPrompts()
        if candidates.isEmpty {
            status.lastSummary = "No permission prompts visible."
            try? writePermissionBrokerStatus(status, paths: paths)
            return
        }

        for candidate in candidates {
            let decision = permissionBrokerDecision(for: candidate.snapshot, config: config)
            let kind = decision.shouldClick ? (dryRun ? "wouldClick" : "clicked") : "ignored"
            var event = PermissionBrokerEvent(
                kind: kind,
                ownerName: candidate.snapshot.ownerName,
                ownerBundleId: candidate.snapshot.ownerBundleId,
                windowTitle: candidate.snapshot.windowTitle,
                promptText: candidate.snapshot.promptText,
                buttonLabel: decision.buttonLabel,
                requesterMatched: decision.requesterMatched,
                actionResult: decision.reason,
                activeJobId: activeJobId()
            )

            if decision.shouldClick, let label = decision.buttonLabel {
                let fingerprint = permissionPromptFingerprint(candidate.snapshot, buttonLabel: label)
                if recentlyClicked(fingerprint) {
                    event.kind = "rateLimited"
                    event.actionResult = "recently clicked this prompt"
                } else if dryRun {
                    event.actionResult = "dry run"
                } else if let button = candidate.buttons.first(where: { $0.label.caseInsensitiveCompare(label) == .orderedSame }) {
                    let result = AXUIElementPerformAction(button.element, kAXPressAction as CFString)
                    if result == .success {
                        recentActions[fingerprint] = Date()
                        event.actionResult = "pressed \(label)"
                        status.lastActionAt = event.timestamp
                    } else {
                        event.kind = "error"
                        event.actionResult = "AX press failed: \(result.rawValue)"
                    }
                } else {
                    event.kind = "error"
                    event.actionResult = "button disappeared before click"
                }
            }

            try? appendPermissionBrokerEvent(event, paths: paths)
            status.lastEventId = event.eventId
            status.lastSummary = "\(event.kind): \(event.ownerName) \(event.windowTitle) \(event.actionResult)"
            try? writePermissionBrokerStatus(status, paths: paths)

            if decision.shouldClick { break }
        }
    }

    private func activeJobId() -> String? {
        let stores = RuntimeStores(paths: paths)
        return (try? stores.state.load().activeJob?.jobId) ?? nil
    }

    private func recentlyClicked(_ fingerprint: String) -> Bool {
        let cutoff = Date().addingTimeInterval(-30)
        recentActions = recentActions.filter { $0.value > cutoff }
        return recentActions[fingerprint] != nil
    }

    private func collectPrompts() -> [PromptCandidate] {
        NSWorkspace.shared.runningApplications.flatMap { app -> [PromptCandidate] in
            guard !app.isTerminated else { return [] }
            let ownerName = app.localizedName ?? app.bundleIdentifier ?? "pid \(app.processIdentifier)"
            let ownerBundleId = app.bundleIdentifier
            guard shouldInspect(ownerName: ownerName, bundleId: ownerBundleId) else { return [] }
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            let windows = axArray(axApp, kAXWindowsAttribute)
            return windows.compactMap { window in
                promptCandidate(window: window, ownerName: ownerName, ownerBundleId: ownerBundleId)
            }
        }
    }

    private func shouldInspect(ownerName: String, bundleId: String?) -> Bool {
        let combined = "\(ownerName)\n\(bundleId ?? "")"
        return config.trustedPromptOwners.contains { combined.localizedCaseInsensitiveContains($0) }
            || config.trustedRequesters.contains { combined.localizedCaseInsensitiveContains($0) }
    }

    private func promptCandidate(window: AXUIElement, ownerName: String, ownerBundleId: String?) -> PromptCandidate? {
        let role = axString(window, kAXRoleAttribute)
        let subrole = axString(window, kAXSubroleAttribute)
        let title = axString(window, kAXTitleAttribute)
        let texts = collectTexts(window)
        let buttons = collectButtons(window)
        let promptText = texts
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .uniqued()
            .joined(separator: "\n")
        let combined = [role, subrole, title, promptText, buttons.map(\.label).joined(separator: " ")].joined(separator: "\n")
        guard !buttons.isEmpty, looksLikePermissionPrompt(combined) || role == "AXDialog" || subrole == "AXDialog" else { return nil }
        let snapshot = PermissionPromptSnapshot(
            ownerName: ownerName,
            ownerBundleId: ownerBundleId,
            windowTitle: title,
            promptText: promptText.isEmpty ? combined : promptText,
            buttonLabels: buttons.map(\.label)
        )
        return PromptCandidate(snapshot: snapshot, buttons: buttons)
    }
}

private func requestAccessibilityTrust() -> Bool {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

private struct PromptCandidate {
    var snapshot: PermissionPromptSnapshot
    var buttons: [AXButton]
}

private struct AXButton {
    var label: String
    var element: AXUIElement
}

private func collectTexts(_ element: AXUIElement, depth: Int = 0) -> [String] {
    guard depth < 7 else { return [] }
    var texts: [String] = []
    for attr in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute, kAXHelpAttribute] {
        let value = axString(element, attr)
        if !value.isEmpty { texts.append(value) }
    }
    for child in axArray(element, kAXChildrenAttribute) {
        texts += collectTexts(child, depth: depth + 1)
    }
    return texts
}

private func collectButtons(_ element: AXUIElement, depth: Int = 0) -> [AXButton] {
    guard depth < 7 else { return [] }
    var buttons: [AXButton] = []
    if axString(element, kAXRoleAttribute) == "AXButton" {
        let label = axString(element, kAXTitleAttribute)
        if !label.isEmpty {
            buttons.append(AXButton(label: label, element: element))
        }
    }
    for child in axArray(element, kAXChildrenAttribute) {
        buttons += collectButtons(child, depth: depth + 1)
    }
    return buttons
}

private func axArray(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
          let array = value as? [AXUIElement] else { return [] }
    return array
}

private func axString(_ element: AXUIElement, _ attribute: String) -> String {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
          let value else { return "" }
    if let string = value as? String { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return ""
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
