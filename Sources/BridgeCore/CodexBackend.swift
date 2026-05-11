import Foundation

public struct CodexBackendFailure: Error, CustomStringConvertible {
    public var message: String
    public var stdout: String
    public var stderr: String
    public var timedOut: Bool
    public var blockedText: String?

    public var description: String { message }
}

public protocol CodexBackend: AnyObject, Sendable {
    func invoke(_ request: PromptRequest, sessionId: String?, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse
}

public enum CodexStreamEvent: Equatable, Sendable {
    case processStarted(Int32)
    case sessionStarted(String)
    case turnStarted(String)
    case progress(String)
    case milestone(String)
    case blocker(String)
    case question(String)
}

public func composeCodexPrompt(_ promptText: String, stylePrompt: String?) -> String {
    [BridgeConstants.baseBridgeInstructions, stylePrompt, promptText]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
}
