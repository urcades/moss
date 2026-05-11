import AppKit
import BridgeCore
import Foundation
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let paths = RuntimePaths.current()
    private var doctorWindow: NSWindow?
    private var trustedSendersWindow: TrustedSendersWindowController?
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3.0"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.title = "CodexMsg"
        rebuildMenu()
        Task { await bootstrapQuietly() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Messages Codex Bridge \(appVersion)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Run Doctor", action: #selector(runDoctor), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Computer Use Probe", action: #selector(runComputerUseProbe), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Trusted Senders...", action: #selector(showTrustedSenders), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Permission Broker Status", action: #selector(showPermissionBrokerStatus), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Permission Broker Dry-Run Scan", action: #selector(runPermissionBrokerDryRun), keyEquivalent: "y"))
        menu.addItem(NSMenuItem(title: "Open Full Disk Access Settings", action: #selector(openFullDiskAccessSettings), keyEquivalent: "f"))
        menu.addItem(NSMenuItem(title: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), keyEquivalent: "a"))
        menu.addItem(NSMenuItem(title: "Open Screen Recording Settings", action: #selector(openScreenRecordingSettings), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Open Automation Settings", action: #selector(openAutomationSettings), keyEquivalent: "m"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Register Login Helper", action: #selector(registerHelper), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Unregister Login Helper", action: #selector(unregisterHelper), keyEquivalent: "u"))
        menu.addItem(NSMenuItem(title: "Reset Codex Session", action: #selector(resetSession), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Open Logs", action: #selector(openLogs), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    @objc private func runDoctor() {
        Task { await showDoctor(probe: false) }
    }

    @objc private func runComputerUseProbe() {
        Task { await showDoctor(probe: true) }
    }

    @objc private func showTrustedSenders() {
        if trustedSendersWindow == nil {
            trustedSendersWindow = TrustedSendersWindowController(paths: paths)
        }
        trustedSendersWindow?.show()
    }

    private func bootstrapQuietly() async {
        do {
            let hadConfig = FileManager.default.fileExists(atPath: paths.configPath.path)
            _ = try Migration(paths: paths).migrateFromExistingRuntime(backup: false)
            if let appBundle = runningAppBundleURL() {
                try await ServiceLifecycle(paths: paths).startHelperLaunchAgent(appBundle: appBundle)
            }
            let config = try RuntimeStores(paths: paths).config.load()
            if !hadConfig && config.effectiveTrustedSenders.isEmpty {
                await MainActor.run { showTrustedSenders() }
            }
        } catch {
            await MainActor.run {
                alert("Bridge setup needs attention.", "\(error)\n\nRun Doctor or Open Logs for details.")
            }
        }
    }

    private func runningAppBundleURL() -> URL? {
        let url = Bundle.main.bundleURL
        return url.pathExtension == "app" ? url : nil
    }

    @objc private func showPermissionBrokerStatus() {
        let status = readPermissionBrokerStatus(paths: paths)
        let events = recentPermissionBrokerEvents(paths: paths, limit: 5)
        let body = """
        Permission Broker
        Running: \(status?.running == true ? "yes" : "unknown")
        Accessibility trusted: \(status?.accessibilityTrusted == true ? "yes" : "no")
        Mode: \(status?.mode ?? "unknown")
        Last scan: \(status?.lastScanAt ?? "none")
        Last action: \(status?.lastActionAt ?? "none")
        Last update: \(status?.lastSummary ?? "none")

        Recent events:
        \(events.isEmpty ? "none" : events.map { "\($0.timestamp) \($0.kind): \($0.ownerName) \($0.buttonLabel ?? "-") \($0.actionResult)" }.joined(separator: "\n"))
        """
        showReportWindow(title: "Permission Broker Status", body: body)
    }

    @objc private func runPermissionBrokerDryRun() {
        Task {
            let executable = FileManager.default.fileExists(atPath: paths.installedPermissionBrokerExecutablePath.path)
                ? paths.installedPermissionBrokerExecutablePath.path
                : paths.builtPermissionBrokerExecutablePath.path
            _ = try? await ProcessRunner().run(executable, ["--dry-run-scan"])
            await MainActor.run { showPermissionBrokerStatus() }
        }
    }

    @objc private func openFullDiskAccessSettings() {
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    }

    @objc private func openAccessibilitySettings() {
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    @objc private func openScreenRecordingSettings() {
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    @objc private func openAutomationSettings() {
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    @objc private func registerHelper() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.loginItem(identifier: BridgeConstants.helperBundleIdentifier).register()
                alert("Login helper registered.", "macOS may ask you to confirm it in Login Items.")
            } catch {
                alert("Could not register login helper.", "\(error)")
            }
        } else {
            alert("Unsupported macOS version.", "Login helper registration requires macOS 13 or newer.")
        }
    }

    @objc private func unregisterHelper() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.loginItem(identifier: BridgeConstants.helperBundleIdentifier).unregister()
                alert("Login helper unregistered.", "")
            } catch {
                alert("Could not unregister login helper.", "\(error)")
            }
        }
    }

    @objc private func resetSession() {
        do {
            let stores = RuntimeStores(paths: paths)
            var state = try stores.state.load()
            state.codexSession = CodexSessionState()
            try stores.state.save(state)
            alert("Codex session reset.", "The next message will start fresh.")
        } catch {
            alert("Could not reset session.", "\(error)")
        }
    }

    @objc private func openLogs() {
        NSWorkspace.shared.open(paths.logsDir)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func showDoctor(probe: Bool) async {
        let doctor = Doctor(paths: paths)
        let report = await doctor.run(includeComputerUseProbe: probe)
        let body = doctor.format(report)
        await MainActor.run {
            showReportWindow(title: report.ok ? "Doctor passed." : "Doctor found issues.", body: body)
        }
    }

    private func showReportWindow(title: String, body: String) {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 720, height: 420))
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false

        let textView = NSTextView(frame: scroll.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = body
        textView.textContainerInset = NSSize(width: 14, height: 14)
        scroll.documentView = textView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.center()
        window.contentView = scroll
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        doctorWindow = window
    }

    private func openSettings(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func alert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}

@MainActor
final class TrustedSendersWindowController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let stores: RuntimeStores
    private var window: NSWindow?
    private var tableView: NSTableView?
    private var senders: [String] = []

    init(paths: RuntimePaths) {
        self.stores = RuntimeStores(paths: paths)
        super.init()
    }

    func show() {
        loadSenders()
        if window == nil {
            buildWindow()
        }
        tableView?.reloadData()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        senders.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("TrustedSenderCell")
        let field: NSTextField
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField {
            field = reused
        } else {
            field = NSTextField(labelWithString: "")
            field.identifier = identifier
            field.lineBreakMode = .byTruncatingMiddle
        }
        field.stringValue = senders[row]
        return field
    }

    private func buildWindow() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 270))

        let scroll = NSScrollView(frame: NSRect(x: 14, y: 46, width: 432, height: 210))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.autoresizingMask = [.width, .height]

        let table = NSTableView(frame: scroll.bounds)
        table.headerView = nil
        table.usesAlternatingRowBackgroundColors = false
        table.allowsMultipleSelection = true
        table.delegate = self
        table.dataSource = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("sender"))
        column.title = "Sender"
        column.width = 420
        table.addTableColumn(column)
        scroll.documentView = table

        let addButton = NSButton(title: "+", target: self, action: #selector(addSender))
        addButton.frame = NSRect(x: 14, y: 12, width: 28, height: 24)
        addButton.bezelStyle = .rounded

        let removeButton = NSButton(title: "-", target: self, action: #selector(removeSelectedSenders))
        removeButton.frame = NSRect(x: 46, y: 12, width: 28, height: 24)
        removeButton.bezelStyle = .rounded

        content.addSubview(scroll)
        content.addSubview(addButton)
        content.addSubview(removeButton)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 270),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Trusted Senders"
        newWindow.isReleasedWhenClosed = false
        newWindow.minSize = NSSize(width: 360, height: 210)
        newWindow.contentView = content
        newWindow.center()
        self.tableView = table
        self.window = newWindow
    }

    @objc private func addSender() {
        let alert = NSAlert()
        alert.messageText = "Add Trusted Sender"
        alert.informativeText = "Enter a phone number or Apple ID email."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.placeholderString = "+1 555 555 5555 or name@example.com"
        alert.accessoryView = field

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        let next = normalizedTrustedSenderList(senders + [value])
        guard next.count != senders.count else {
            NSSound.beep()
            return
        }
        senders = next
        saveSenders()
    }

    @objc private func removeSelectedSenders() {
        guard let tableView else { return }
        let selected = tableView.selectedRowIndexes
        guard !selected.isEmpty else { return }
        senders = senders.enumerated().filter { !selected.contains($0.offset) }.map(\.element)
        saveSenders()
    }

    private func loadSenders() {
        do {
            var config = try stores.config.load()
            migrateTrustedSenders(&config)
            try stores.config.save(config)
            senders = config.effectiveTrustedSenders
        } catch {
            senders = []
        }
    }

    private func saveSenders() {
        do {
            var config = try stores.config.load()
            config.syncTrustedSenders(senders)
            try validateConfig(config)
            try stores.config.save(config)
            senders = config.effectiveTrustedSenders
            tableView?.reloadData()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not save trusted senders."
            alert.informativeText = "\(error)"
            alert.runModal()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
