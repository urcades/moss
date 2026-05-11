# Troubleshooting

Start with the menu item `Run Doctor`, or run:

```sh
mossctl doctor
```

From a local source checkout, you can also run:

```sh
swift run codexmsgctl-swift doctor
```

To share diagnostics in an issue, use `Diagnostics > Copy Doctor Report` from
the menu-bar app or paste the CLI Doctor output.

## Full Disk Access

Symptom: Doctor reports the Messages database is not readable.

Fix: grant Full Disk Access to Messages Codex Bridge in System Settings. If the
helper is running from the installed runtime copy, grant access to that app copy
too when macOS shows it.

## Messages Automation

Symptom: Doctor reports Messages automation is unreachable or replies do not send.

Fix: open the app, run Doctor, and allow Automation access to Messages when
macOS prompts. You can also open System Settings with the app menu item
`Open Automation Settings`.

## Accessibility And Screen Recording

Symptom: Computer Use or permission recovery fails.

Fix: grant Accessibility and Screen Recording to Codex, Codex Computer Use, and
Messages Codex Permission Broker when Doctor reports they are missing.

## Codex CLI Missing

Symptom: Doctor reports `Codex CLI available` as failed.

Fix: install Codex.app and confirm this path exists:

```sh
/Applications/Codex.app/Contents/Resources/codex
```

## Helper Or Broker LaunchAgent

Symptom: status says the helper or broker LaunchAgent is not loaded.

Fix:

```sh
./BuildSupport/install-local-app.zsh --safety standard
swift run codexmsgctl-swift status
```

For Homebrew installs, use:

```sh
mossctl status
```

For a deeper check:

```sh
launchctl print "gui/$(id -u)/com.moss.MessagesCodexBridge.Helper"
launchctl print "gui/$(id -u)/com.moss.MessagesCodexBridge.PermissionBroker"
```

## App-Server Capability Failures

Symptom: Doctor reports Codex app-server, remote-control, or thread/read as unavailable.

Fix: update Codex.app, rerun Doctor, and confirm the configured Codex command
points to the bundled Codex CLI.

## Logs

Use the menu item `Open Logs`, or inspect:

```sh
open "$HOME/Library/Logs/MessagesLLMBridge"
```
