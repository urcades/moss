import BridgeCore
import Foundation

@main
struct MessagesCodexBridgeHelper {
    static func main() async {
        let paths = RuntimePaths.current()
        let logURL = paths.logsDir.appendingPathComponent("swift-helper.log")
        try? FileManager.default.createDirectory(at: paths.logsDir, withIntermediateDirectories: true)
        append("Helper starting.", to: logURL)

        do {
            try await BridgeService(paths: paths).runForever()
        } catch {
            append("Helper failed: \(error)", to: logURL)
            fputs("MessagesCodexBridgeHelper failed: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func append(_ line: String, to url: URL) {
        let text = "\(DateCodec.iso()) \(line)\n"
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path), let handle = try? FileHandle(forWritingTo: url) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            } else {
                try? data.write(to: url)
            }
        }
    }
}
