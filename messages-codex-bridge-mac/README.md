# Messages Codex Bridge Mac

Native Swift/macOS bridge for using Apple Messages as a prompt channel for `codex exec`.

This is the active Swift bridge implementation. It keeps the existing runtime paths under:

- `~/Library/Application Support/MessagesLLMBridge/`
- `~/Library/Logs/MessagesLLMBridge/`

The native bridge runs from a signed menu-bar app plus a login helper:

- App bundle id: `com.moss.MessagesCodexBridge`
- Helper bundle id: `com.moss.MessagesCodexBridge.Helper`

## Development

```sh
./BuildSupport/check-active-bridge.zsh
swift build
swift run BridgeCoreTests
swift run BridgeCoreSelfTest
swift run codexmsgctl-swift status
swift run codexmsgctl-swift doctor
swift run MessagesCodexBridgeHelper
swift run MessagesCodexBridgeApp
```

`codexmsgctl-swift install` prepares the existing runtime config/state, backs them up, and starts the Swift helper LaunchAgent.

## Bundle Build

```sh
SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./BuildSupport/build-app.zsh
open .build/app/MessagesCodexBridge.app
```

The script creates a signed `.app` and embeds the helper under `Contents/Library/LoginItems/`. If `SIGN_IDENTITY` is omitted it uses the local `Messages Codex Bridge Local Code Signing` identity when present, otherwise it falls back to ad hoc signing for build verification.

To create the local signing identity:

```sh
./BuildSupport/create-local-signing-identity.zsh
./BuildSupport/build-app.zsh
```

Use the app menu to register the helper and run the Computer Use probe.

Use `Trusted Senders...` in the app menu to choose which phone numbers or Apple ID
emails may send prompts to the bridge. Fresh installs start with no trusted
senders until one is added.

## Apple Messages control commands

Send these exact messages from the configured sender to control the Swift bridge without forwarding the text to Codex:

- `/codex status` replies with the active Codex thread id/link, active job state, latest progress, and Codex 0.130 capability status.
- `/codex open` opens the active Codex thread in Codex.app with `codex://threads/<id>`.
- `/codex history` starts a temporary local `codex app-server --listen stdio://` client, reads `thread/read`, and replies with a compact summary of the last loaded turns.

`codexmsgctl-swift status` and `codexmsgctl-swift doctor` also report whether the installed Codex supports app-server, `remote-control`, and `thread/read`. These checks use a short-lived Swift capability cache. Missing enhanced capabilities are reported as warnings/degraded status, not as a hard bridge failure.

## Permission Model

The native app intentionally creates a stable TCC identity. Do not edit TCC databases directly. Use the app's Doctor and Computer Use Probe actions to trigger/check:

- Full Disk Access for Messages DB reads
- Automation for Messages replies
- Automation to `com.openai.sky.CUAService` for Computer Use
- Accessibility and Screen Recording for Codex/Computer Use
