# Uninstall

Messages Codex Bridge installs source-build artifacts under your home directory
and uses user LaunchAgents. It does not install system-wide files.

## Stop Running Services

```sh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.moss.MessagesCodexBridge.Helper.plist" 2>/dev/null || true
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.moss.MessagesCodexBridge.PermissionBroker.plist" 2>/dev/null || true
osascript -e 'tell application id "com.moss.MessagesCodexBridge" to quit' 2>/dev/null || true
```

## Remove Installed App And LaunchAgents

```sh
rm -rf "$HOME/Applications/MessagesCodexBridge.app"
rm -f "$HOME/Library/LaunchAgents/com.moss.MessagesCodexBridge.Helper.plist"
rm -f "$HOME/Library/LaunchAgents/com.moss.MessagesCodexBridge.PermissionBroker.plist"
```

## Optional: Remove Runtime State And Logs

This deletes trusted senders, bridge state, logs, and helper status files.

```sh
rm -rf "$HOME/Library/Application Support/MessagesLLMBridge"
rm -rf "$HOME/Library/Logs/MessagesLLMBridge"
```

## Optional: Remove Build Output

From the repository root:

```sh
rm -rf .build .swiftpm
```

macOS privacy permissions granted in System Settings remain visible to macOS
until the system prunes them or you remove them from System Settings.
