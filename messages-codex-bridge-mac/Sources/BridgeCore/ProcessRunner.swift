import Foundation

public struct ProcessResult: Equatable, Sendable {
    public var stdout: String
    public var stderr: String
    public var exitCode: Int32
}

public enum ProcessRunnerError: Error, CustomStringConvertible, Sendable {
    case failedToStart(String)
    case timedOut(String)
    case blocked(String, ProcessResult)
    case nonZero(String, ProcessResult)

    public var description: String {
        switch self {
        case .failedToStart(let message), .timedOut(let message):
            return message
        case .blocked(let message, let result):
            let detail = [result.stdout, result.stderr].filter { !$0.isEmpty }.joined(separator: "\n")
            return detail.isEmpty ? message : "\(message): \(detail)"
        case .nonZero(let message, let result):
            let detail = [result.stdout, result.stderr].filter { !$0.isEmpty }.joined(separator: "\n")
            return detail.isEmpty ? message : "\(message): \(detail)"
        }
    }
}

public enum ProcessOutputStream: Sendable {
    case stdout
    case stderr
}

public typealias ProcessOutputInspector = @Sendable (_ recentOutput: String) -> String?
public typealias ProcessOutputHandler = @Sendable (_ stream: ProcessOutputStream, _ chunk: String) -> Void
public typealias ProcessStartHandler = @Sendable (_ processIdentifier: Int32) -> Void

public final class ProcessRunner: @unchecked Sendable {
    public init() {}

    public func run(_ executable: String, _ arguments: [String], cwd: String? = nil, stdin: String? = nil, timeoutMs: Int? = nil, outputInspector: ProcessOutputInspector? = nil, outputHandler: ProcessOutputHandler? = nil, onStart: ProcessStartHandler? = nil) async throws -> ProcessResult {
        try await Task.detached {
            try Self.runBlocking(executable, arguments, cwd: cwd, stdin: stdin, timeoutMs: timeoutMs, outputInspector: outputInspector, outputHandler: outputHandler, onStart: onStart)
        }.value
    }

    private static func runBlocking(_ executable: String, _ arguments: [String], cwd: String?, stdin: String?, timeoutMs: Int?, outputInspector: ProcessOutputInspector?, outputHandler: ProcessOutputHandler?, onStart: ProcessStartHandler?) throws -> ProcessResult {
        let process = Process()
        if executable.contains("/") {
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [executable] + arguments
        }
        if let cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        let inputPipe = stdin == nil ? nil : Pipe()
        if let inputPipe {
            process.standardInput = inputPipe
        }

        let output = ProcessOutputBuffer()
        let blockedMessage = AtomicString()
        if outputInspector != nil {
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                output.appendStdout(data)
                if let text = String(data: data, encoding: .utf8) {
                    outputHandler?(.stdout, text)
                }
                if let message = outputInspector?(output.recentCombined(maxBytes: 64 * 1024)), blockedMessage.setIfEmpty(message), process.isRunning {
                    process.terminate()
                }
            }
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                output.appendStderr(data)
                if let text = String(data: data, encoding: .utf8) {
                    outputHandler?(.stderr, text)
                }
                if let message = outputInspector?(output.recentCombined(maxBytes: 64 * 1024)), blockedMessage.setIfEmpty(message), process.isRunning {
                    process.terminate()
                }
            }
        }

        do {
            try process.run()
        } catch {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            throw ProcessRunnerError.failedToStart("Failed to start \(executable): \(error.localizedDescription)")
        }
        onStart?(process.processIdentifier)

        if let stdin, let inputPipe {
            inputPipe.fileHandleForWriting.write(Data(stdin.utf8))
            try? inputPipe.fileHandleForWriting.close()
        }

        let timedOut = AtomicFlag()
        if let timeoutMs, timeoutMs > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
                if process.isRunning {
                    timedOut.set()
                    process.terminate()
                }
            }
        }

        process.waitUntilExit()
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        if outputInspector == nil {
            output.appendStdout(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
            output.appendStderr(stderrPipe.fileHandleForReading.readDataToEndOfFile())
        } else {
            output.appendStdout(stdoutPipe.fileHandleForReading.availableData)
            output.appendStderr(stderrPipe.fileHandleForReading.availableData)
        }

        let result = ProcessResult(stdout: output.stdout(), stderr: output.stderr(), exitCode: process.terminationStatus)

        if timedOut.get() {
            throw ProcessRunnerError.timedOut("\(executable) timed out after \(timeoutMs ?? 0)ms")
        }

        if let message = blockedMessage.get() {
            throw ProcessRunnerError.blocked(message, result)
        }

        if process.terminationStatus != 0 {
            throw ProcessRunnerError.nonZero("\(executable) exited with code \(process.terminationStatus)", result)
        }
        return result
    }
}

private final class ProcessOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var stdoutData = Data()
    private var stderrData = Data()

    func appendStdout(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        stdoutData.append(data)
        lock.unlock()
    }

    func appendStderr(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        stderrData.append(data)
        lock.unlock()
    }

    func stdout() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: stdoutData, encoding: .utf8) ?? ""
    }

    func stderr() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: stderrData, encoding: .utf8) ?? ""
    }

    func combined() -> String {
        lock.lock()
        defer { lock.unlock() }
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        return [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    func recentCombined(maxBytes: Int) -> String {
        lock.lock()
        defer { lock.unlock() }
        let stdout = String(decoding: stdoutData.suffix(maxBytes), as: UTF8.self)
        let stderr = String(decoding: stderrData.suffix(maxBytes), as: UTF8.self)
        return [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

private final class AtomicFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set() {
        lock.lock()
        value = true
        lock.unlock()
    }

    func get() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private final class AtomicString: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?

    func setIfEmpty(_ newValue: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard value == nil else { return false }
        value = newValue
        return true
    }

    func get() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
