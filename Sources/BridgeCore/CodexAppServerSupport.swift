import Foundation

public struct CodexCapabilities: Codable, Equatable, Sendable {
    public var version: String?
    public var appServerAvailable: Bool
    public var remoteControlAvailable: Bool
    public var threadReadAvailable: Bool
    public var inventory: CodexToolInventory?
    public var warnings: [String]

    public init(version: String?, appServerAvailable: Bool, remoteControlAvailable: Bool, threadReadAvailable: Bool, inventory: CodexToolInventory? = nil, warnings: [String]) {
        self.version = version
        self.appServerAvailable = appServerAvailable
        self.remoteControlAvailable = remoteControlAvailable
        self.threadReadAvailable = threadReadAvailable
        self.inventory = inventory
        self.warnings = warnings
    }

    public var enhancedBridgeUXAvailable: Bool {
        version != nil &&
        appServerAvailable &&
        remoteControlAvailable &&
        threadReadAvailable &&
        !warnings.contains { $0.contains("0.130.0") }
    }
}

public struct CodexToolInventory: Codable, Equatable, Sendable {
    public var skills: [CodexSkillInventoryItem]
    public var plugins: [CodexPluginInventoryItem]
    public var apps: [CodexAppInventoryItem]
    public var mcpServers: [CodexMcpServerInventoryItem]
    public var warnings: [String]

    public init(
        skills: [CodexSkillInventoryItem] = [],
        plugins: [CodexPluginInventoryItem] = [],
        apps: [CodexAppInventoryItem] = [],
        mcpServers: [CodexMcpServerInventoryItem] = [],
        warnings: [String] = []
    ) {
        self.skills = skills
        self.plugins = plugins
        self.apps = apps
        self.mcpServers = mcpServers
        self.warnings = warnings
    }

    public var enabledSkillCount: Int {
        skills.filter(\.enabled).count
    }

    public var accessibleAppCount: Int {
        apps.filter(\.isAccessible).count
    }

    public var mcpToolCount: Int {
        mcpServers.reduce(0) { $0 + $1.toolCount }
    }
}

public struct CodexSkillInventoryItem: Codable, Equatable, Sendable {
    public var name: String
    public var description: String?
    public var path: String?
    public var enabled: Bool

    public init(name: String, description: String? = nil, path: String? = nil, enabled: Bool = true) {
        self.name = name
        self.description = description
        self.path = path
        self.enabled = enabled
    }
}

public struct CodexPluginInventoryItem: Codable, Equatable, Sendable {
    public var name: String
    public var displayName: String?
    public var skillCount: Int
    public var appCount: Int
    public var mcpServerCount: Int

    public init(name: String, displayName: String? = nil, skillCount: Int = 0, appCount: Int = 0, mcpServerCount: Int = 0) {
        self.name = name
        self.displayName = displayName
        self.skillCount = skillCount
        self.appCount = appCount
        self.mcpServerCount = mcpServerCount
    }
}

public struct CodexAppInventoryItem: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var description: String?
    public var isAccessible: Bool
    public var isEnabled: Bool
    public var pluginDisplayNames: [String]
    public var labels: [String: String]

    public init(id: String, name: String, description: String? = nil, isAccessible: Bool = false, isEnabled: Bool = false, pluginDisplayNames: [String] = [], labels: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.isAccessible = isAccessible
        self.isEnabled = isEnabled
        self.pluginDisplayNames = pluginDisplayNames
        self.labels = labels
    }
}

public struct CodexMcpServerInventoryItem: Codable, Equatable, Sendable {
    public var name: String
    public var toolCount: Int
    public var resourceCount: Int
    public var resourceTemplateCount: Int
    public var authStatus: String?

    public init(name: String, toolCount: Int = 0, resourceCount: Int = 0, resourceTemplateCount: Int = 0, authStatus: String? = nil) {
        self.name = name
        self.toolCount = toolCount
        self.resourceCount = resourceCount
        self.resourceTemplateCount = resourceTemplateCount
        self.authStatus = authStatus
    }
}

public enum CapabilityInvocationStatus: String, Codable, Equatable, Sendable {
    case discovered
    case callable
    case blocked
    case unsupported
}

public struct CodexCapabilityInvocation: Codable, Equatable, Sendable {
    public var name: String
    public var status: CapabilityInvocationStatus
    public var detail: String

    public init(name: String, status: CapabilityInvocationStatus, detail: String) {
        self.name = name
        self.status = status
        self.detail = detail
    }
}

public struct CodexCapabilitySnapshot: Equatable, Sendable {
    public var capabilities: CodexCapabilities
    public var cachedAt: String
    public var refreshed: Bool
    public var cacheAgeSeconds: Int?

    public init(capabilities: CodexCapabilities, cachedAt: String, refreshed: Bool, cacheAgeSeconds: Int?) {
        self.capabilities = capabilities
        self.cachedAt = cachedAt
        self.refreshed = refreshed
        self.cacheAgeSeconds = cacheAgeSeconds
    }
}

private struct CodexCapabilityCacheEntry: Codable {
    var cachedAt: String
    var capabilities: CodexCapabilities
}

public struct CodexThreadTurnSummary: Equatable, Sendable {
    public var status: String
    public var updatedAt: String
    public var userPreview: String
    public var answerPreview: String

    public init(status: String, updatedAt: String, userPreview: String, answerPreview: String) {
        self.status = status
        self.updatedAt = updatedAt
        self.userPreview = userPreview
        self.answerPreview = answerPreview
    }
}

public struct CodexThreadHistory: Equatable, Sendable {
    public var threadId: String
    public var turns: [CodexThreadTurnSummary]

    public init(threadId: String, turns: [CodexThreadTurnSummary]) {
        self.threadId = threadId
        self.turns = turns
    }
}

public enum CodexAppServerError: Error, CustomStringConvertible, Equatable, Sendable {
    case invalidResponse(String)
    case processError(String)
    case rpcError(String)
    case timedOut(String)

    public var description: String {
        switch self {
        case .invalidResponse(let message), .processError(let message), .rpcError(let message), .timedOut(let message):
            return message
        }
    }
}

public typealias CodexInteractiveCallbackResponder = @Sendable (_ method: String, _ requestId: Any, _ params: [String: Any]?) throws -> [String: Any]

public protocol CodexAppServerConnection: AnyObject, Sendable {
    func start() throws
    func send(_ message: [String: Any]) throws
    func readLine(deadline: Date) throws -> String?
    func close()
    var processIdentifier: Int32? { get }
    var diagnostics: String { get }
}

public final class CodexAppServerClient: @unchecked Sendable {
    private let makeConnection: @Sendable () throws -> CodexAppServerConnection
    private let timeoutMs: Int

    public convenience init(command: String, timeoutMs: Int = 15_000) {
        self.init(timeoutMs: timeoutMs) {
            ProcessCodexAppServerConnection(command: command)
        }
    }

    public init(timeoutMs: Int = 15_000, makeConnection: @escaping @Sendable () throws -> CodexAppServerConnection) {
        self.timeoutMs = timeoutMs
        self.makeConnection = makeConnection
    }

    public func threadRead(threadId: String, includeTurns: Bool = true) async throws -> CodexThreadHistory {
        let timeoutMs = timeoutMs
        let makeConnection = makeConnection
        return try await Task.detached {
            let connection = try makeConnection()
            let rpc = CodexAppServerRPC(connection: connection, timeoutMs: timeoutMs)
            defer { rpc.close() }
            try rpc.initialize()
            let result = try rpc.request(method: "thread/read", params: [
                "threadId": threadId,
                "includeTurns": includeTurns
            ])
            return codexThreadHistory(from: result, fallbackThreadId: threadId)
        }.value
    }

    public func capabilityInventory(cwd: String, forceReload: Bool = false) async throws -> CodexToolInventory {
        let timeoutMs = timeoutMs
        let makeConnection = makeConnection
        return try await Task.detached {
            let connection = try makeConnection()
            let rpc = CodexAppServerRPC(connection: connection, timeoutMs: timeoutMs)
            defer { rpc.close() }
            try rpc.initialize()

            var inventory = CodexToolInventory()
            inventory.skills = try rpc.optionalRequest(
                method: "skills/list",
                params: ["cwds": [cwd], "forceReload": forceReload],
                warning: &inventory.warnings
            ).map(codexSkillInventoryItems) ?? []
            inventory.plugins = try rpc.optionalRequest(
                method: "plugin/list",
                params: ["cwds": [cwd]],
                warning: &inventory.warnings
            ).map(codexPluginInventoryItems) ?? []
            inventory.apps = try rpc.optionalRequest(
                method: "app/list",
                params: ["limit": 200, "forceRefetch": forceReload],
                warning: &inventory.warnings
            ).map(codexAppInventoryItems) ?? []
            inventory.mcpServers = try rpc.optionalRequest(
                method: "mcpServerStatus/list",
                params: ["limit": 200, "detail": "toolsAndAuthOnly"],
                warning: &inventory.warnings
            ).map(codexMcpServerInventoryItems) ?? []
            return inventory
        }.value
    }
}

public final class CodexAppServerBackend: CodexBackend, @unchecked Sendable {
    private let config: BridgeConfig
    private let paths: RuntimePaths
    private let makeConnection: @Sendable () throws -> CodexAppServerConnection
    private let interactiveCallbackResponder: CodexInteractiveCallbackResponder?

    public convenience init(config: BridgeConfig, paths: RuntimePaths) {
        self.init(config: config, paths: paths, interactiveCallbackResponder: nil) {
            ProcessCodexAppServerConnection(command: config.codex.command)
        }
    }

    public convenience init(config: BridgeConfig, paths: RuntimePaths, interactiveCallbackResponder: CodexInteractiveCallbackResponder?) {
        self.init(config: config, paths: paths, interactiveCallbackResponder: interactiveCallbackResponder) {
            ProcessCodexAppServerConnection(command: config.codex.command)
        }
    }

    public init(config: BridgeConfig, paths: RuntimePaths, interactiveCallbackResponder: CodexInteractiveCallbackResponder? = nil, makeConnection: @escaping @Sendable () throws -> CodexAppServerConnection) {
        self.config = config
        self.paths = paths
        self.makeConnection = makeConnection
        self.interactiveCallbackResponder = interactiveCallbackResponder
    }

    public func invoke(_ request: PromptRequest, sessionId: String?, onEvent: (@Sendable (CodexStreamEvent) -> Void)?) async throws -> CodexResponse {
        let config = config
        let paths = paths
        let makeConnection = makeConnection
        let interactiveCallbackResponder = interactiveCallbackResponder
        return try await Task.detached {
            let collector = CodexAppServerTurnCollector(onEvent: onEvent)
            let connection = try makeConnection()
            let rpc = CodexAppServerRPC(connection: connection, timeoutMs: config.timeoutMs, onNotification: { message in
                collector.handleNotification(message)
            }, interactiveCallbackResponder: interactiveCallbackResponder)
            defer { rpc.close() }

            do {
                try rpc.initialize()
                if let pid = connection.processIdentifier {
                    onEvent?(.processStarted(pid))
                }

                let threadId: String
                if let sessionId, !sessionId.isEmpty {
                    let resume = try rpc.request(method: "thread/resume", params: appServerThreadResumeParams(config: config, paths: paths, threadId: sessionId))
                    threadId = appServerThreadId(from: resume, fallback: sessionId)
                } else {
                    let start = try rpc.request(method: "thread/start", params: appServerThreadStartParams(config: config, paths: paths))
                    threadId = appServerThreadId(from: start, fallback: nil)
                }
                guard !threadId.isEmpty else {
                    throw CodexBackendFailure(
                        message: "Codex app-server did not return a thread id.",
                        stdout: "",
                        stderr: connection.diagnostics,
                        timedOut: false,
                        blockedText: nil
                    )
                }
                if sessionId == nil, let threadName = appServerThreadName(from: request) {
                    _ = try? rpc.request(method: "thread/name/set", params: appServerThreadNameParams(threadId: threadId, name: threadName))
                }
                collector.setThreadId(threadId)
                onEvent?(.sessionStarted(threadId))

                let turn = try rpc.request(method: "turn/start", params: appServerTurnStartParams(config: config, request: request, threadId: threadId))
                if let turnId = appServerTurnId(from: turn) {
                    collector.setTurnId(turnId)
                    onEvent?(.turnStarted(turnId))
                }

                let completed = try rpc.readNotifications(until: { message in
                    collector.handleNotification(message)
                    return collector.isFinished
                })
                if !completed {
                    throw CodexBackendFailure(
                        message: "Timed out waiting for Codex app-server turn to finish.",
                        stdout: "",
                        stderr: connection.diagnostics,
                        timedOut: true,
                        blockedText: permissionBlock(in: connection.diagnostics)
                    )
                }
                if let failure = collector.failure(diagnostics: connection.diagnostics) {
                    throw failure
                }
                guard let finalText = collector.finalAnswer else {
                    throw CodexBackendFailure(
                        message: "Codex app-server completed without a final reply.",
                        stdout: "",
                        stderr: connection.diagnostics,
                        timedOut: false,
                        blockedText: permissionBlock(in: connection.diagnostics)
                    )
                }
                return CodexResponse(
                    text: finalText,
                    sessionId: threadId,
                    stdout: "",
                    stderr: connection.diagnostics,
                    args: ["app-server", "--listen", "stdio://"],
                    outputPath: collector.outputPath ?? ""
                )
            } catch let error as CodexBackendFailure {
                throw error
            } catch let error as CodexAppServerError {
                throw CodexBackendFailure(
                    message: "Codex app-server error: \(error.description)",
                    stdout: "",
                    stderr: connection.diagnostics,
                    timedOut: {
                        if case .timedOut = error { return true }
                        return false
                    }(),
                    blockedText: permissionBlock(in: error.description + "\n" + connection.diagnostics)
                )
            } catch {
                throw CodexBackendFailure(
                    message: "Codex app-server error: \(error)",
                    stdout: "",
                    stderr: connection.diagnostics,
                    timedOut: String(describing: error).localizedCaseInsensitiveContains("timed out"),
                    blockedText: permissionBlock(in: String(describing: error) + "\n" + connection.diagnostics)
                )
            }
        }.value
    }
}

private final class CodexAppServerRPC {
    private let connection: CodexAppServerConnection
    private let timeoutMs: Int
    private let onNotification: (([String: Any]) -> Void)?
    private let interactiveCallbackResponder: CodexInteractiveCallbackResponder?
    private var nextId = 1

    init(connection: CodexAppServerConnection, timeoutMs: Int, onNotification: (([String: Any]) -> Void)? = nil, interactiveCallbackResponder: CodexInteractiveCallbackResponder? = nil) {
        self.connection = connection
        self.timeoutMs = timeoutMs
        self.onNotification = onNotification
        self.interactiveCallbackResponder = interactiveCallbackResponder
    }

    func initialize() throws {
        try connection.start()
        _ = try request(method: "initialize", params: [
            "clientInfo": [
                "name": "messages_codex_bridge_swift",
                "title": "Messages Codex Bridge",
                "version": "0.3.1"
            ],
            "capabilities": [
                "experimentalApi": true
            ]
        ])
        try connection.send(["method": "initialized", "params": [:]])
    }

    func request(method: String, params: [String: Any]) throws -> [String: Any] {
        let id = nextId
        nextId += 1
        try connection.send(["id": id, "method": method, "params": params])
        return try readResponse(id: id)
    }

    func optionalRequest(method: String, params: [String: Any], warning warnings: inout [String]) throws -> [String: Any]? {
        do {
            return try request(method: method, params: params)
        } catch let error as CodexAppServerError {
            warnings.append("\(method) unavailable: \(error.description)")
            return nil
        }
    }

    func close() {
        connection.close()
    }

    private func readResponse(id: Int) throws -> [String: Any] {
        let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
        let finished = LockedBool()
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) { [connection] in
            if !finished.get() {
                connection.close()
            }
        }
        defer { finished.set(true) }
        while Date() < deadline {
            guard let message = try readMessage(deadline: deadline) else { break }
            if let responseId = jsonRpcId(message["id"]), responseId == id {
                if let error = message["error"] as? [String: Any] {
                    throw CodexAppServerError.rpcError(searchableText(error["message"] ?? error))
                }
                guard let result = message["result"] as? [String: Any] else {
                    throw CodexAppServerError.invalidResponse("Codex app-server response \(id) did not include an object result.")
                }
                return result
            }
            if try handleServerRequestIfNeeded(message) {
                continue
            }
            onNotification?(message)
        }
        let detail = connection.diagnostics.trimmingCharacters(in: .whitespacesAndNewlines)
        throw CodexAppServerError.timedOut(detail.isEmpty ? "Timed out waiting for Codex app-server response \(id)." : "Timed out waiting for Codex app-server response \(id): \(detail)")
    }

    func readNotifications(until predicate: ([String: Any]) -> Bool) throws -> Bool {
        let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
        let finished = LockedBool()
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) { [connection] in
            if !finished.get() {
                connection.close()
            }
        }
        defer { finished.set(true) }
        while Date() < deadline {
            guard let message = try readMessage(deadline: deadline) else { break }
            if try handleServerRequestIfNeeded(message) {
                if predicate(message) {
                    return true
                }
                continue
            }
            if predicate(message) {
                return true
            }
        }
        return false
    }

    private func readMessage(deadline: Date) throws -> [String: Any]? {
        while Date() < deadline {
            guard let line = try connection.readLine(deadline: deadline) else {
                return nil
            }
            guard let data = line.data(using: .utf8),
                  let message = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                continue
            }
            return message
        }
        return nil
    }

    private func handleServerRequestIfNeeded(_ message: [String: Any]) throws -> Bool {
        guard let requestId = message["id"],
              let method = message["method"] as? String else {
            return false
        }
        guard method == "item/tool/call" ||
            method == "item/tool/requestUserInput" ||
            method == "mcpServer/elicitation/request" else {
            return false
        }
        let response = try serverRequestResponse(method: method, requestId: requestId, params: message["params"] as? [String: Any])
        onNotification?(serverRequestNotification(method: method, response: response))
        var reply = response
        reply["id"] = requestId
        try connection.send(reply)
        return true
    }

    private func serverRequestResponse(method: String, requestId: Any, params: [String: Any]?) throws -> [String: Any] {
        switch method {
        case "item/tool/call":
            return try dynamicToolCallResponse(params: params)
        case "item/tool/requestUserInput":
            if let interactiveCallbackResponder {
                return try interactiveCallbackResponder(method, requestId, params)
            }
            return unsupportedInteractiveCallbackResponse(
                "Codex app-server requires interactive user input that the Messages bridge cannot answer. Ask the user to continue in Codex Desktop or send a new Messages reply with the requested choice."
            )
        case "mcpServer/elicitation/request":
            if let interactiveCallbackResponder {
                return try interactiveCallbackResponder(method, requestId, params)
            }
            return unsupportedInteractiveCallbackResponse(
                "Codex app-server requires MCP elicitation that the Messages bridge cannot answer. Ask the user to continue in Codex Desktop or send a new Messages reply with the requested confirmation."
            )
        default:
            return [
                "error": [
                    "code": -32601,
                    "message": "Unsupported app-server request: \(method)"
                ]
            ]
        }
    }

    private func dynamicToolCallResponse(params: [String: Any]?) throws -> [String: Any] {
        guard let params,
              let tool = params["tool"] as? String,
              let threadId = params["threadId"] as? String else {
            return ["result": dynamicToolFailure("Dynamic tool call was missing required thread/tool fields.")]
        }
        guard let server = mcpServerName(forDynamicToolNamespace: params["namespace"] as? String) else {
            let name = dynamicToolDisplayName(namespace: params["namespace"] as? String, tool: tool)
            return ["result": dynamicToolFailure("\(name) is known to Codex, but this bridge can only execute MCP-backed dynamic tools from app-server.")]
        }

        do {
            let arguments = params["arguments"] ?? [String: Any]()
            let meta = params["_meta"] ?? NSNull()
            let result = try request(method: "mcpServer/tool/call", params: [
                "threadId": threadId,
                "server": server,
                "tool": tool,
                "arguments": arguments,
                "_meta": meta
            ])
            return ["result": dynamicToolResponse(fromMcpResult: result)]
        } catch {
            let name = dynamicToolDisplayName(namespace: params["namespace"] as? String, tool: tool)
            return ["result": dynamicToolFailure("\(name) failed through app-server MCP forwarding: \(error)")]
        }
    }
}

private func unsupportedInteractiveCallbackResponse(_ message: String) -> [String: Any] {
    [
        "error": [
            "code": -32004,
            "message": message
        ]
    ]
}

private func mcpServerName(forDynamicToolNamespace namespace: String?) -> String? {
    let raw = (namespace ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !raw.isEmpty else { return nil }
    if raw == "codex_app" || raw == "codex_apps" || raw == "mcp__codex_apps__" {
        return "codex_apps"
    }
    if raw.hasPrefix("mcp__"), raw.hasSuffix("__"), raw.count > 7 {
        let start = raw.index(raw.startIndex, offsetBy: 5)
        let end = raw.index(raw.endIndex, offsetBy: -2)
        return String(raw[start..<end])
    }
    if raw.range(of: #"^[A-Za-z0-9_-]+$"#, options: .regularExpression) != nil {
        return raw
    }
    return nil
}

private func dynamicToolDisplayName(namespace: String?, tool: String) -> String {
    [namespace, tool]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ".")
}

private func dynamicToolFailure(_ text: String) -> [String: Any] {
    [
        "success": false,
        "contentItems": [
            ["type": "inputText", "text": text]
        ]
    ]
}

private func dynamicToolResponse(fromMcpResult result: [String: Any]) -> [String: Any] {
    let isError = result["isError"] as? Bool ?? false
    let content = result["content"] as? [Any] ?? []
    let contentItems = dynamicToolContentItems(fromMcpContent: content)
    let fallback: [[String: Any]] = [
        ["type": "inputText", "text": isError ? "Tool failed without content." : "Tool completed without text output."]
    ]
    return [
        "success": !isError,
        "contentItems": contentItems.isEmpty ? fallback : contentItems
    ]
}

private func dynamicToolContentItems(fromMcpContent content: [Any]) -> [[String: Any]] {
    content.compactMap { item in
        if let object = item as? [String: Any] {
            let type = object["type"] as? String
            if type == "text", let text = object["text"] as? String {
                return ["type": "inputText", "text": text]
            }
            if type == "image", let url = object["imageUrl"] as? String ?? object["url"] as? String {
                return ["type": "inputImage", "imageUrl": url]
            }
            if let text = object["text"] as? String {
                return ["type": "inputText", "text": text]
            }
            return ["type": "inputText", "text": dynamicToolSearchableText(object)]
        }
        return ["type": "inputText", "text": searchableText(item)]
    }
}

private func dynamicToolSearchableText(_ value: Any) -> String {
    if let string = value as? String { return string }
    if let array = value as? [Any] { return array.map(dynamicToolSearchableText).joined(separator: "\n") }
    if let dict = value as? [String: Any] {
        return dict
            .keys
            .sorted()
            .map { key in
                let text = dynamicToolSearchableText(dict[key] ?? "")
                return text.isEmpty ? key : "\(key): \(text)"
            }
            .joined(separator: "\n")
    }
    return "\(value)"
}

private func serverRequestNotification(method: String, response: [String: Any]) -> [String: Any] {
    let succeeded = response["result"] != nil
    let detail = succeeded ? "Handled app-server request \(method)." : searchableText(response["error"] ?? response)
    return [
        "method": succeeded ? "bridge/serverRequest/resolved" : "bridge/serverRequest/unsupported",
        "params": [
            "method": method,
            "status": succeeded ? "handled" : "failed",
            "detail": detail
        ]
    ]
}

private final class CodexAppServerTurnCollector: @unchecked Sendable {
    private let lock = NSLock()
    private let onEvent: (@Sendable (CodexStreamEvent) -> Void)?
    private var threadId: String?
    private var turnId: String?
    private var finished = false
    private var errorText: String?
    private var finalText: String?
    private var agentMessageBuffers: [String: String] = [:]
    private var sessionPath: String?

    init(onEvent: (@Sendable (CodexStreamEvent) -> Void)?) {
        self.onEvent = onEvent
    }

    var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finished
    }

    var finalAnswer: String? {
        lock.lock()
        defer { lock.unlock() }
        return finalText.map(cleanPlainText).flatMap { $0.isEmpty ? nil : $0 }
    }

    var outputPath: String? {
        lock.lock()
        defer { lock.unlock() }
        return sessionPath
    }

    func setThreadId(_ id: String) {
        lock.lock()
        threadId = id
        lock.unlock()
    }

    func setTurnId(_ id: String) {
        lock.lock()
        turnId = id
        lock.unlock()
    }

    func failure(diagnostics: String) -> CodexBackendFailure? {
        lock.lock()
        let text = errorText
        lock.unlock()
        guard let text, !text.isEmpty else { return nil }
        return CodexBackendFailure(
            message: text,
            stdout: "",
            stderr: diagnostics,
            timedOut: false,
            blockedText: permissionBlock(in: text + "\n" + diagnostics)
        )
    }

    func handleNotification(_ message: [String: Any]) {
        guard let method = message["method"] as? String else { return }
        let params = message["params"] as? [String: Any] ?? [:]
        var events: [CodexStreamEvent] = []

        lock.lock()
        switch method {
        case "thread/started":
            if let thread = params["thread"] as? [String: Any] {
                if let id = thread["id"] as? String {
                    threadId = id
                    events.append(.sessionStarted(id))
                }
                if let path = thread["path"] as? String {
                    sessionPath = path
                }
            }
        case "turn/started":
            if let id = (params["turn"] as? [String: Any])?["id"] as? String ?? params["turnId"] as? String {
                turnId = id
                events.append(.turnStarted(id))
            }
        case "item/agentMessage/delta":
            if let itemId = params["itemId"] as? String, let delta = params["delta"] as? String {
                agentMessageBuffers[itemId, default: ""] += delta
            }
        case "item/completed":
            if let item = params["item"] as? [String: Any] {
                if appServerItemIndicatesFailure(item), let block = permissionBlock(in: searchableText(item)) {
                    events.append(.blocker(block))
                }
                if item["type"] as? String == "agentMessage" {
                    let phase = item["phase"] as? String ?? ""
                    let text = textValue(in: item, keys: ["text", "message", "content"]) ?? ((item["id"] as? String).flatMap { agentMessageBuffers[$0] })
                    if phase == "final_answer" || phase == "final" {
                        finalText = text
                    }
                }
            }
        case "error":
            errorText = cleanPlainText(searchableText(params["error"] ?? params))
        case "turn/completed":
            if let turn = params["turn"] as? [String: Any],
               let error = turn["error"], !(error is NSNull) {
                errorText = cleanPlainText(searchableText(error))
            }
            finished = true
        case "thread/status/changed":
            if let status = params["status"] as? [String: Any],
               status["type"] as? String == "systemError",
               errorText == nil {
                errorText = "Codex app-server reported a system error."
            }
        case "bridge/serverRequest/unsupported":
            if let detail = params["detail"] as? String {
                events.append(.blocker(detail))
                errorText = detail
                finished = true
            }
        default:
            break
        }
        if let summary = codexProgressSummary(from: message) {
            events.append(.progress(summary))
        }
        lock.unlock()

        for event in events {
            onEvent?(event)
        }
    }
}

private func appServerItemIndicatesFailure(_ item: [String: Any]) -> Bool {
    let status = (item["status"] as? String ?? "").lowercased()
    if ["failed", "failure", "error"].contains(status) {
        return true
    }
    if let error = item["error"], !(error is NSNull) {
        return true
    }
    return false
}

private func appServerThreadStartParams(config: BridgeConfig, paths: RuntimePaths) -> [String: Any] {
    var params: [String: Any] = [
        "cwd": config.codex.cwd,
        "approvalPolicy": "never",
        "sandbox": "danger-full-access",
        "ephemeral": false,
        "sessionStartSource": "clear",
        "threadSource": "user"
    ]
    if let instructions = bridgeDeveloperInstructions(config: config, paths: paths) {
        params["developerInstructions"] = instructions
    }
    return params
}

private func appServerThreadResumeParams(config: BridgeConfig, paths: RuntimePaths, threadId: String) -> [String: Any] {
    var params: [String: Any] = [
        "threadId": threadId,
        "cwd": config.codex.cwd,
        "approvalPolicy": "never",
        "sandbox": "danger-full-access"
    ]
    if let instructions = bridgeDeveloperInstructions(config: config, paths: paths) {
        params["developerInstructions"] = instructions
    }
    return params
}

private func appServerThreadNameParams(threadId: String, name: String) -> [String: Any] {
    [
        "threadId": threadId,
        "name": name
    ]
}

private func appServerTurnStartParams(config: BridgeConfig, request: PromptRequest, threadId: String) -> [String: Any] {
    [
        "threadId": threadId,
        "input": appServerInputItems(from: request),
        "cwd": config.codex.cwd,
        "approvalPolicy": "never",
        "sandboxPolicy": appServerSandboxPolicy(for: request)
    ]
}

private func appServerSandboxPolicy(for request: PromptRequest) -> [String: Any] {
    if promptLooksLikeCodexAutomationRequest(request.promptText) {
        return ["type": "readOnly"]
    }
    return ["type": "dangerFullAccess"]
}

private func appServerInputItems(from request: PromptRequest) -> [[String: Any]] {
    var items: [[String: Any]] = [
        [
            "type": "text",
            "text": request.promptText,
            "text_elements": []
        ]
    ]
    for mention in extractCodexMentionRefs(from: request.promptText) {
        items.append([
            "type": "mention",
            "name": mention.name,
            "path": mention.path
        ])
    }
    for attachment in request.attachments where attachment.kind == "image" && attachment.exists {
        if let path = attachment.absolutePath {
            items.append(["type": "localImage", "path": path])
        }
    }
    return items
}

private func appServerThreadName(from request: PromptRequest) -> String? {
    request.threadName.flatMap(cleanThreadNameCandidate)
}

private func cleanThreadNameCandidate(_ value: String) -> String? {
    let text = value
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return nil }
    return truncateForMessages(text, limit: 80)
}

private func bridgeDeveloperInstructions(config: BridgeConfig, paths: RuntimePaths) -> String? {
    let text = [BridgeConstants.baseBridgeInstructions, config.codex.stylePrompt, cachedCodexCapabilityPromptContext(paths: paths)]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    return text.isEmpty ? nil : text
}

private func cachedCodexCapabilityPromptContext(paths: RuntimePaths) -> String? {
    guard let snapshot = loadCachedCodexCapabilities(paths: paths, now: Date(), ttlMs: Int.max),
          let inventory = snapshot.capabilities.inventory else {
        return nil
    }
    let accessibleApps = inventory.apps.filter(\.isAccessible).map(\.name)
    let enabledSkills = inventory.skills.filter(\.enabled).map(\.name)
    let invocationLines = capabilityInvocationStatusLines(for: inventory)
    return """
    Current Codex capability inventory from app-server cache:
    - Enabled skills: \(inventory.enabledSkillCount)\(sampleSuffix(enabledSkills, limit: 12))
    - Accessible apps/connectors: \(inventory.accessibleAppCount)\(sampleSuffix(accessibleApps, limit: 12))
    - MCP servers: \(inventory.mcpServers.count), MCP tools: \(inventory.mcpToolCount)\(sampleSuffix(inventory.mcpServers.map(\.name), limit: 12))
    - Invocation status: \(invocationLines.joined(separator: "; "))
    Use these as Codex capabilities when the app-server exposes them during the turn. Treat "discovered" as awareness, not callability; if a named capability is not callable in this Messages-launched turn, say that specific limitation plainly.
    """
}

public let defaultCodexMentionAliases: [String: String] = [
    "Chrome": "plugin://chrome@openai-bundled",
    "Browser": "plugin://browser@openai-bundled",
    "Computer Use": "plugin://computer-use@openai-bundled"
]

public func extractCodexMentionRefs(from text: String, aliases: [String: String] = defaultCodexMentionAliases) -> [CodexMentionRef] {
    let source = text
    var mentions: [CodexMentionRef] = []
    var seen = Set<String>()

    for match in regexMatches(#"\[([^\]]+)\]\((plugin://[^\s),.;]+|app://[^\s),.;]+)\)"#, in: source, options: [.caseInsensitive]) {
        guard match.count == 3 else { continue }
        appendMention(name: normalizeMentionName(match[1]), path: match[2], mentions: &mentions, seen: &seen)
    }

    for match in regexMatches(#"(?<![A-Za-z0-9_])(plugin://[^\s),.;]+|app://[^\s),.;]+)"#, in: source, options: [.caseInsensitive]) {
        guard match.count == 2 else { continue }
        appendMention(name: mentionName(fromPath: match[1]), path: match[1], mentions: &mentions, seen: &seen)
    }

    for (name, path) in aliases {
        if hasBareAliasMention(source, alias: name) || hasNaturalLanguageAliasMention(source, alias: name, path: path) {
            appendMention(name: name, path: path, mentions: &mentions, seen: &seen)
        }
    }

    return mentions
}

private func regexMatches(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
    let nsText = text as NSString
    let range = NSRange(location: 0, length: nsText.length)
    return regex.matches(in: text, range: range).map { match in
        (0..<match.numberOfRanges).map { index in
            let matchRange = match.range(at: index)
            guard matchRange.location != NSNotFound else { return "" }
            return nsText.substring(with: matchRange)
        }
    }
}

private func appendMention(name: String, path: String, mentions: inout [CodexMentionRef], seen: inout Set<String>) {
    let normalizedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard normalizedPath.hasPrefix("plugin://") || normalizedPath.hasPrefix("app://") else { return }
    let normalizedName = normalizeMentionName(name)
    guard !normalizedName.isEmpty else { return }
    let key = normalizedPath.lowercased()
    guard seen.insert(key).inserted else { return }
    mentions.append(CodexMentionRef(name: normalizedName, path: normalizedPath))
}

private func normalizeMentionName(_ name: String) -> String {
    var text = name.trimmingCharacters(in: .whitespacesAndNewlines)
    while text.hasPrefix("@") {
        text.removeFirst()
    }
    return text
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func mentionName(fromPath path: String) -> String {
    let normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
    if normalized.hasPrefix("plugin://") {
        let body = String(normalized.dropFirst("plugin://".count))
        let plugin = body.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? body
        return plugin
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
    if normalized.hasPrefix("app://") {
        let body = String(normalized.dropFirst("app://".count))
        return body.isEmpty ? "App" : body
    }
    return normalized
}

private func hasBareAliasMention(_ text: String, alias: String) -> Bool {
    let escaped = NSRegularExpression.escapedPattern(for: alias)
    return text.range(of: #"(?<![A-Za-z0-9_])@\#(escaped)(?![A-Za-z0-9_])"#, options: [.regularExpression, .caseInsensitive]) != nil
}

private func hasNaturalLanguageAliasMention(_ text: String, alias: String, path: String) -> Bool {
    let normalized = normalizeMentionName(alias)
    guard !normalized.isEmpty else { return false }
    if text.localizedCaseInsensitiveContains("[@\(normalized)](\(path))") {
        return true
    }
    let escaped = NSRegularExpression.escapedPattern(for: normalized)
    return text.range(of: #"(?<![A-Za-z0-9_])use\s+\#(escaped)(?![A-Za-z0-9_])"#, options: [.regularExpression, .caseInsensitive]) != nil
}

public func capabilityInvocations(for inventory: CodexToolInventory) -> [CodexCapabilityInvocation] {
    let mcpServers = Set(inventory.mcpServers.filter { $0.toolCount > 0 }.map { $0.name.lowercased() })
    let enabledSkills = Set(inventory.skills.filter(\.enabled).map { $0.name.lowercased() })
    var result: [CodexCapabilityInvocation] = []

    if enabledSkills.contains("chrome:chrome") {
        let callable = mcpServers.contains("node_repl")
        result.append(CodexCapabilityInvocation(
            name: "Chrome",
            status: callable ? .callable : .discovered,
            detail: callable ? "node_repl MCP is callable" : "Chrome skill is enabled, but node_repl MCP is not in the callable inventory"
        ))
    }
    if enabledSkills.contains("browser:browser") || enabledSkills.contains("browser-use:browser") {
        result.append(CodexCapabilityInvocation(
            name: "Browser",
            status: .discovered,
            detail: "browser skill is enabled; callable browser backend depends on app-server dynamic tool forwarding"
        ))
    }
    if enabledSkills.contains("computer-use:computer-use") || mcpServers.contains("computer-use") {
        let callable = mcpServers.contains("computer-use")
        result.append(CodexCapabilityInvocation(
            name: "Computer Use",
            status: callable ? .callable : .discovered,
            detail: callable ? "computer-use MCP is callable" : "Computer Use skill is enabled, but MCP server is not callable"
        ))
    }
    if inventory.accessibleAppCount > 0 {
        let callable = mcpServers.contains("codex_apps")
        result.append(CodexCapabilityInvocation(
            name: "Apps/connectors",
            status: callable ? .callable : .discovered,
            detail: callable ? "codex_apps MCP is callable" : "apps are accessible, but codex_apps MCP is not callable"
        ))
    }
    return result
}

private func capabilityInvocationStatusLines(for inventory: CodexToolInventory) -> [String] {
    let invocations = capabilityInvocations(for: inventory)
    guard !invocations.isEmpty else {
        return ["no named capability callability hints"]
    }
    return invocations.map { "\($0.name): \($0.status.rawValue) (\($0.detail))" }
}

private func appServerThreadId(from result: [String: Any], fallback: String?) -> String {
    if let id = (result["thread"] as? [String: Any])?["id"] as? String ?? result["id"] as? String ?? fallback {
        return id
    }
    return ""
}

private func appServerTurnId(from result: [String: Any]) -> String? {
    (result["turn"] as? [String: Any])?["id"] as? String ?? result["turnId"] as? String ?? result["id"] as? String
}

private final class ProcessCodexAppServerConnection: CodexAppServerConnection, @unchecked Sendable {
    private let command: String
    private let process = Process()
    private let stdin = Pipe()
    private let stdout = Pipe()
    private let stderr = Pipe()
    private let diagnosticsBuffer = LockedDataBuffer()

    init(command: String) {
        self.command = command
    }

    var diagnostics: String {
        diagnosticsBuffer.string()
    }

    var processIdentifier: Int32? {
        process.isRunning ? process.processIdentifier : nil
    }

    func start() throws {
        if command.contains("/") {
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = ["app-server", "--listen", "stdio://"]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command, "app-server", "--listen", "stdio://"]
        }
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
        stderr.fileHandleForReading.readabilityHandler = { [diagnosticsBuffer] handle in
            let data = handle.availableData
            if !data.isEmpty {
                diagnosticsBuffer.append(data)
            }
        }
        do {
            try process.run()
        } catch {
            stderr.fileHandleForReading.readabilityHandler = nil
            throw CodexAppServerError.processError("Failed to start Codex app-server: \(error.localizedDescription)")
        }
    }

    func send(_ message: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: message)
        stdin.fileHandleForWriting.write(data)
        stdin.fileHandleForWriting.write(Data("\n".utf8))
    }

    func readLine(deadline: Date) throws -> String? {
        var data = Data()
        while Date() < deadline {
            let chunk = stdout.fileHandleForReading.readData(ofLength: 1)
            if chunk.isEmpty {
                return data.isEmpty ? nil : String(data: data, encoding: .utf8)
            }
            if chunk == Data("\n".utf8) {
                return String(data: data, encoding: .utf8)
            }
            data.append(chunk)
        }
        return nil
    }

    func close() {
        stderr.fileHandleForReading.readabilityHandler = nil
        if process.isRunning {
            terminateProcessTree(rootPid: process.processIdentifier)
        }
        try? stdin.fileHandleForWriting.close()
    }
}

private final class LockedDataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ newData: Data) {
        lock.lock()
        data.append(newData)
        lock.unlock()
    }

    func string() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

private final class LockedBool: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set(_ newValue: Bool) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    func get() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

public func codexThreadDeepLink(_ threadId: String) -> String {
    "codex://threads/\(threadId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? threadId)"
}

public func openCodexThread(_ threadId: String, runner: ProcessRunner = ProcessRunner()) async throws {
    _ = try await runner.run("/usr/bin/open", ["-g", codexThreadDeepLink(threadId)])
}

public func cachedCodexCapabilities(
    command: String,
    runner: ProcessRunner = ProcessRunner(),
    paths: RuntimePaths = .current(),
    ttlMs: Int = 300_000,
    now: Date = Date()
) async -> CodexCapabilitySnapshot {
    if let cached = loadCachedCodexCapabilities(paths: paths, now: now, ttlMs: ttlMs) {
        return cached
    }
    let capabilities = await probeCodexCapabilities(command: command, runner: runner, paths: paths)
    let cachedAt = DateCodec.iso(now)
    saveCachedCodexCapabilities(CodexCapabilityCacheEntry(cachedAt: cachedAt, capabilities: capabilities), paths: paths)
    return CodexCapabilitySnapshot(capabilities: capabilities, cachedAt: cachedAt, refreshed: true, cacheAgeSeconds: 0)
}

public func cachedCodexCapabilitiesBestEffort(
    command: String,
    runner: ProcessRunner = ProcessRunner(),
    paths: RuntimePaths = .current(),
    ttlMs: Int = Int.max,
    refreshTimeoutMs: Int = 10_000,
    now: Date = Date()
) async -> CodexCapabilitySnapshot? {
    if let cached = loadCachedCodexCapabilities(paths: paths, now: now, ttlMs: ttlMs) {
        return cached
    }
    return await codexAsyncTimeout(nanoseconds: UInt64(max(1, refreshTimeoutMs)) * 1_000_000) {
        await cachedCodexCapabilities(command: command, runner: runner, paths: paths, ttlMs: 0, now: now)
    }
}

public func probeCodexCapabilities(command: String, runner: ProcessRunner = ProcessRunner(), paths: RuntimePaths = .current()) async -> CodexCapabilities {
    var version: String?
    var warnings: [String] = []

    do {
        let result = try await runner.run(command, ["--version"], timeoutMs: 10_000)
        version = parseCodexVersion(result.stdout)
        if version == nil || compareCodexVersion(version ?? "0.0.0", minimum: "0.130.0") < 0 {
            warnings.append("Codex 0.130.0 or newer is recommended for enhanced bridge UX.")
        }
    } catch {
        warnings.append("Unable to read Codex version: \(error)")
    }

    let appServerAvailable = (try? await runner.run(command, ["app-server", "--help"], timeoutMs: 10_000)) != nil
    let remoteControlAvailable = (try? await runner.run(command, ["remote-control", "--help"], timeoutMs: 10_000)) != nil
    let threadReadAvailable = await codexThreadReadAvailable(command: command, runner: runner, paths: paths)
    var inventory: CodexToolInventory?

    if !appServerAvailable {
        warnings.append("Codex app-server command is unavailable.")
    } else {
        do {
            let loaded = try await CodexAppServerClient(command: command, timeoutMs: 20_000)
                .capabilityInventory(cwd: paths.defaultCodexCwd.path)
            inventory = loaded
            warnings += loaded.warnings.map { "Codex capability inventory warning: \($0)" }
        } catch {
            warnings.append("Unable to read Codex app-server capability inventory: \(error)")
        }
    }
    if !remoteControlAvailable {
        warnings.append("Codex remote-control command is unavailable.")
    }
    if !threadReadAvailable {
        warnings.append("Codex app-server thread/read support is unavailable.")
    }

    return CodexCapabilities(
        version: version,
        appServerAvailable: appServerAvailable,
        remoteControlAvailable: remoteControlAvailable,
        threadReadAvailable: threadReadAvailable,
        inventory: inventory,
        warnings: warnings
    )
}

public func formatCodexCapabilityLines(_ capabilities: CodexCapabilities) -> [String] {
    var lines = [
        "Codex version: \(capabilities.version ?? "unknown")",
        "Codex app-server: \(capabilities.appServerAvailable ? "yes" : "no")",
        "Codex remote-control: \(capabilities.remoteControlAvailable ? "yes" : "no")",
        "Codex thread/read: \(capabilities.threadReadAvailable ? "yes" : "no")",
        "Enhanced bridge UX: \(capabilities.enhancedBridgeUXAvailable ? "yes" : "degraded")"
    ]
    if let inventory = capabilities.inventory {
        lines += formatCodexToolInventoryLines(inventory)
    } else {
        lines.append("Codex tool inventory: unavailable")
    }
    lines += capabilities.warnings.map { "WARNING  \($0)" }
    return lines
}

public func formatCodexToolInventoryLines(_ inventory: CodexToolInventory) -> [String] {
    var lines = [
        "Codex skills: \(inventory.enabledSkillCount) enabled / \(inventory.skills.count) total\(sampleSuffix(inventory.skills.map(\.name)))",
        "Codex plugins: \(inventory.plugins.count)\(sampleSuffix(inventory.plugins.map { $0.displayName ?? $0.name }))",
        "Codex apps/connectors: \(inventory.accessibleAppCount) accessible / \(inventory.apps.count) total\(sampleSuffix(inventory.apps.filter(\.isAccessible).map(\.name)))",
        "Codex MCP servers: \(inventory.mcpServers.count), tools: \(inventory.mcpToolCount)\(sampleSuffix(inventory.mcpServers.map(\.name)))",
        "Codex invocation status: \(capabilityInvocationStatusLines(for: inventory).joined(separator: "; "))"
    ]
    lines += inventory.warnings.map { "WARNING  \($0)" }
    return lines
}

private func sampleSuffix(_ values: [String], limit: Int = 5) -> String {
    let names = values
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    guard !names.isEmpty else { return "" }
    let shown = names.prefix(limit).joined(separator: ", ")
    return names.count > limit ? " (\(shown), ...)" : " (\(shown))"
}

public func formatCodexCapabilityCacheLine(_ snapshot: CodexCapabilitySnapshot) -> String {
    if snapshot.refreshed {
        return "Codex capability cache: refreshed at \(snapshot.cachedAt)"
    }
    return "Codex capability cache: cached at \(snapshot.cachedAt), age \(snapshot.cacheAgeSeconds ?? 0)s"
}

public func readCodexThreadHistory(command: String, threadId: String, timeoutMs: Int = 15_000) async throws -> String {
    let history = try await CodexAppServerClient(command: command, timeoutMs: timeoutMs).threadRead(threadId: threadId, includeTurns: true)
    return formatCodexThreadHistory(history)
}

public func codexSkillInventoryItems(from result: [String: Any]) -> [CodexSkillInventoryItem] {
    let entries = result["data"] as? [[String: Any]] ?? []
    let skills = entries.flatMap { entry -> [[String: Any]] in
        if let skills = entry["skills"] as? [[String: Any]] {
            return skills
        }
        return [entry]
    }
    return skills.compactMap { item in
        guard let name = item["name"] as? String, !name.isEmpty else { return nil }
        return CodexSkillInventoryItem(
            name: name,
            description: item["description"] as? String ?? item["shortDescription"] as? String,
            path: item["path"] as? String,
            enabled: item["enabled"] as? Bool ?? true
        )
    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

public func codexPluginInventoryItems(from result: [String: Any]) -> [CodexPluginInventoryItem] {
    let marketplaces = result["marketplaces"] as? [[String: Any]] ?? []
    var plugins: [CodexPluginInventoryItem] = []
    for marketplace in marketplaces {
        if let entries = marketplace["plugins"] as? [[String: Any]] ?? marketplace["items"] as? [[String: Any]] {
            plugins += entries.compactMap(codexPluginInventoryItem)
        } else if let item = codexPluginInventoryItem(from: marketplace) {
            plugins.append(item)
        }
    }
    return plugins.sorted { ($0.displayName ?? $0.name).localizedCaseInsensitiveCompare($1.displayName ?? $1.name) == .orderedAscending }
}

private func codexPluginInventoryItem(from item: [String: Any]) -> CodexPluginInventoryItem? {
    let summary = item["summary"] as? [String: Any]
    let name = item["marketplaceName"] as? String ??
        item["name"] as? String ??
        item["id"] as? String ??
        summary?["name"] as? String
    guard let name, !name.isEmpty else { return nil }
    let displayName = item["displayName"] as? String ??
        summary?["displayName"] as? String ??
        summary?["name"] as? String
    return CodexPluginInventoryItem(
        name: name,
        displayName: displayName,
        skillCount: (item["skills"] as? [Any])?.count ?? 0,
        appCount: (item["apps"] as? [Any])?.count ?? 0,
        mcpServerCount: (item["mcpServers"] as? [Any])?.count ?? 0
    )
}

public func codexAppInventoryItems(from result: [String: Any]) -> [CodexAppInventoryItem] {
    let apps = result["data"] as? [[String: Any]] ?? result["apps"] as? [[String: Any]] ?? []
    return apps.compactMap { item in
        guard let id = item["id"] as? String,
              let name = item["name"] as? String,
              !id.isEmpty,
              !name.isEmpty else {
            return nil
        }
        return CodexAppInventoryItem(
            id: id,
            name: name,
            description: item["description"] as? String,
            isAccessible: item["isAccessible"] as? Bool ?? false,
            isEnabled: item["isEnabled"] as? Bool ?? false,
            pluginDisplayNames: item["pluginDisplayNames"] as? [String] ?? [],
            labels: stringDictionary(item["labels"])
        )
    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

public func codexMcpServerInventoryItems(from result: [String: Any]) -> [CodexMcpServerInventoryItem] {
    let servers = result["data"] as? [[String: Any]] ?? result["servers"] as? [[String: Any]] ?? []
    return servers.compactMap { item in
        guard let name = item["name"] as? String, !name.isEmpty else { return nil }
        return CodexMcpServerInventoryItem(
            name: name,
            toolCount: (item["tools"] as? [String: Any])?.count ?? (item["tools"] as? [Any])?.count ?? 0,
            resourceCount: (item["resources"] as? [Any])?.count ?? 0,
            resourceTemplateCount: (item["resourceTemplates"] as? [Any])?.count ?? 0,
            authStatus: searchableText(item["authStatus"] ?? "")
        )
    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

private func stringDictionary(_ value: Any?) -> [String: String] {
    guard let object = value as? [String: Any] else { return [:] }
    var result: [String: String] = [:]
    for (key, value) in object {
        if let string = value as? String {
            result[key] = string
        } else if let bool = value as? Bool {
            result[key] = bool ? "true" : "false"
        } else if let number = value as? NSNumber {
            result[key] = number.stringValue
        }
    }
    return result
}

public func codexThreadHistory(from result: [String: Any], fallbackThreadId: String) -> CodexThreadHistory {
    let thread = result["thread"] as? [String: Any] ?? result
    let threadId = thread["id"] as? String ?? thread["threadId"] as? String ?? fallbackThreadId
    let allTurns = thread["turns"] as? [[String: Any]] ?? result["turns"] as? [[String: Any]] ?? []
    let turns = allTurns.suffix(3).map(codexThreadTurnSummary)
    return CodexThreadHistory(threadId: threadId, turns: turns)
}

public func formatCodexThreadHistory(_ history: CodexThreadHistory) -> String {
    guard !history.turns.isEmpty else {
        return "Codex thread \(history.threadId) has no loaded turns yet.\nCodex thread link: \(codexThreadDeepLink(history.threadId))"
    }
    var lines = [
        "Codex thread \(history.threadId)",
        "Codex thread link: \(codexThreadDeepLink(history.threadId))",
        "Last \(history.turns.count) turn\(history.turns.count == 1 ? "" : "s"):"
    ]
    for (index, turn) in history.turns.enumerated() {
        lines.append("\(index + 1). \(turn.status) at \(turn.updatedAt)")
        lines.append("User: \(turn.userPreview)")
        lines.append("Codex: \(turn.answerPreview)")
    }
    return lines.joined(separator: "\n")
}

public func codexProgressSummary(from event: [String: Any]) -> String? {
    guard let type = event["method"] as? String else { return nil }
    let params = event["params"] as? [String: Any] ?? event["payload"] as? [String: Any] ?? event
    switch type {
    case "turn/started", "turn.started":
        return "Codex turn started."
    case "turn/completed", "turn.completed":
        return "Codex turn completed."
    case "turn/failed", "turn.failed":
        return "Codex turn failed."
    case "item/started", "item.started":
        return codexItemSummary(prefix: "Started", params: params)
    case "item/completed", "item.completed":
        return codexItemSummary(prefix: "Completed", params: params)
    default:
        if type.contains("tool") && type.contains("start") {
            return codexItemSummary(prefix: "Started", params: params)
        }
        if type.contains("tool") && (type.contains("complete") || type.contains("finish")) {
            return codexItemSummary(prefix: "Completed", params: params)
        }
        return nil
    }
}

private func codexItemSummary(prefix: String, params: [String: Any]) -> String? {
    let item = params["item"] as? [String: Any] ?? params
    if (item["status"] as? String)?.lowercased() == "failed" {
        return nil
    }
    let name = item["tool"] as? String ??
        item["name"] as? String ??
        item["command"] as? String ??
        item["type"] as? String ??
        "Codex item"
    let status = item["status"] as? String
    return [prefix, name, status.map { "(\($0))" }].compactMap { $0 }.joined(separator: " ")
}

private func codexThreadTurnSummary(_ turn: [String: Any]) -> CodexThreadTurnSummary {
    let items = turn["items"] as? [[String: Any]] ?? []
    let userText = firstText(in: items, matchingTypes: ["userMessage", "user_message", "user"]) ?? firstText(in: [turn], keys: ["prompt", "userPrompt", "user"])
    let answerText = finalAnswerText(in: items) ?? firstText(in: [turn], keys: ["finalAnswer", "answer", "response"])
    return CodexThreadTurnSummary(
        status: turn["status"] as? String ?? "unknown",
        updatedAt: turnUpdatedAt(turn),
        userPreview: truncateForMessages(cleanPlainText(userText ?? "(no user text loaded)"), limit: 220),
        answerPreview: truncateForMessages(cleanPlainText(answerText ?? "(no final response loaded)"), limit: 220)
    )
}

private func finalAnswerText(in items: [[String: Any]]) -> String? {
    let agentMessages = items.filter { item in
        ["agentMessage", "agent_message", "assistant", "assistantMessage"].contains(item["type"] as? String ?? "")
    }
    let final = agentMessages.last(where: { item in
        let phase = item["phase"] as? String ?? item["role"] as? String ?? ""
        return phase == "final_answer" || phase == "final"
    }) ?? agentMessages.last
    return final.flatMap { textValue(in: $0, keys: ["text", "message", "content"]) }
}

private func firstText(in items: [[String: Any]], matchingTypes types: Set<String>) -> String? {
    items.first { types.contains($0["type"] as? String ?? "") }.flatMap {
        textValue(in: $0, keys: ["content", "text", "message"])
    }
}

private func firstText(in items: [[String: Any]], keys: [String]) -> String? {
    for item in items {
        if let text = textValue(in: item, keys: keys) {
            return text
        }
    }
    return nil
}

private func textValue(in item: [String: Any], keys: [String]) -> String? {
    for key in keys {
        if let value = item[key] {
            let text = searchableText(value).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
    }
    return nil
}

private func turnUpdatedAt(_ turn: [String: Any]) -> String {
    for key in ["updatedAt", "completedAt", "createdAt", "startedAt"] {
        if let string = turn[key] as? String, !string.isEmpty {
            return string
        }
        if let seconds = turn[key] as? Double {
            return DateCodec.iso(Date(timeIntervalSince1970: seconds))
        }
        if let seconds = turn[key] as? Int {
            return DateCodec.iso(Date(timeIntervalSince1970: TimeInterval(seconds)))
        }
    }
    return "unknown time"
}

private func jsonRpcId(_ value: Any?) -> Int? {
    if let int = value as? Int { return int }
    if let double = value as? Double { return Int(double) }
    if let string = value as? String { return Int(string) }
    return nil
}

private func capabilityCachePath(paths: RuntimePaths) -> URL {
    paths.stateDir.appendingPathComponent("codex-capabilities.json")
}

private func loadCachedCodexCapabilities(paths: RuntimePaths, now: Date, ttlMs: Int) -> CodexCapabilitySnapshot? {
    let path = capabilityCachePath(paths: paths)
    guard let data = try? Data(contentsOf: path),
          let entry = try? JSONDecoder().decode(CodexCapabilityCacheEntry.self, from: data),
          let cachedAt = DateCodec.parse(entry.cachedAt) else {
        return nil
    }
    let age = now.timeIntervalSince(cachedAt)
    guard age >= 0, age * 1000 <= Double(ttlMs) else {
        return nil
    }
    return CodexCapabilitySnapshot(capabilities: entry.capabilities, cachedAt: entry.cachedAt, refreshed: false, cacheAgeSeconds: Int(age))
}

private func saveCachedCodexCapabilities(_ entry: CodexCapabilityCacheEntry, paths: RuntimePaths) {
    do {
        try FileManager.default.createDirectory(at: paths.stateDir, withIntermediateDirectories: true)
        let data = try JSONEncoder.pretty.encode(entry)
        try data.write(to: capabilityCachePath(paths: paths), options: .atomic)
    } catch {
        // Capability probing is advisory. The bridge should keep working even when the cache cannot be written.
    }
}

private func codexAsyncTimeout<T: Sendable>(nanoseconds: UInt64, operation: @escaping @Sendable () async -> T) async -> T? {
    await withCheckedContinuation { continuation in
        let resumeOnce = CodexTimeoutResumeOnce()
        let task = Task {
            let value = await operation()
            resumeOnce.run {
                continuation.resume(returning: value)
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: nanoseconds)
            resumeOnce.run {
                task.cancel()
                continuation.resume(returning: nil)
            }
        }
    }
}

private final class CodexTimeoutResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    func run(_ body: () -> Void) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }
        didResume = true
        lock.unlock()
        body()
    }
}

private func codexThreadReadAvailable(command: String, runner: ProcessRunner, paths: RuntimePaths) async -> Bool {
    let tmp = paths.tmpDir.appendingPathComponent("codex-app-server-schema-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }
    guard (try? await runner.run(command, ["app-server", "generate-ts", "--out", tmp.path], timeoutMs: 20_000)) != nil else {
        return false
    }
    let clientRequest = tmp.appendingPathComponent("ClientRequest.ts")
    guard let text = try? String(contentsOf: clientRequest, encoding: .utf8) else {
        return false
    }
    return text.contains("\"thread/read\"")
}

private func parseCodexVersion(_ text: String) -> String? {
    text.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression).map { String(text[$0]) }
}

private func compareCodexVersion(_ version: String, minimum: String) -> Int {
    let left = version.split(separator: ".").map { Int($0) ?? 0 }
    let right = minimum.split(separator: ".").map { Int($0) ?? 0 }
    for index in 0..<max(left.count, right.count) {
        let l = index < left.count ? left[index] : 0
        let r = index < right.count ? right[index] : 0
        if l != r { return l > r ? 1 : -1 }
    }
    return 0
}

func truncateForMessages(_ value: String, limit: Int) -> String {
    let text = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    guard text.count > limit else { return text.isEmpty ? "(empty)" : text }
    return String(text.prefix(max(0, limit - 3))) + "..."
}
