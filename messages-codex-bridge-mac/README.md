# Messages Codex Bridge Mac

Native Swift/macOS bridge for using Apple Messages as a prompt channel for Codex.

This repository currently distributes as a source build. You clone it, build the
menu-bar app locally, open the app, add one or more trusted senders, grant the
macOS permissions the Doctor reports, and then send prompts from Messages.

## Current Distribution Mode

The v0.1.0 release candidate is source-build only:

- Local build from this Swift package.
- Local code signing identity when available.
- Ad hoc signing fallback for development/build verification.
- Zipped/notarized binary distribution is future work.
- A custom app icon is future work.

## Prerequisites

- macOS 15 or newer.
- Git.
- Xcode Command Line Tools or a Swift toolchain that can run `swift build`.
- Apple Messages signed in and able to send/receive the account you want to use.
- Codex.app installed with its bundled CLI available at:

```sh
/Applications/Codex.app/Contents/Resources/codex
```

## Fresh Mac Source Build

Clone the repository and build the app:

```sh
git clone https://github.com/urcades/moss.git
cd moss/messages-codex-bridge-mac
./BuildSupport/build-app.zsh
open .build/app/MessagesCodexBridge.app
```

The build script creates:

- `.build/app/MessagesCodexBridge.app`
- A bundled login helper at `Contents/Library/LoginItems/MessagesCodexBridgeHelper.app`
- A bundled permission broker at `Contents/Library/LoginItems/MessagesCodexPermissionBroker.app`

If no `SIGN_IDENTITY` is provided, the build script uses the local
`Messages Codex Bridge Local Code Signing` identity when present. Otherwise it
falls back to ad hoc signing, which is enough for source-build development.

To create the local signing identity first:

```sh
./BuildSupport/create-local-signing-identity.zsh
./BuildSupport/build-app.zsh
open .build/app/MessagesCodexBridge.app
```

## First Run

When the menu-bar app opens, its menu header should read:

```text
Messages Codex Bridge 0.1.0
```

Use the menu in this order:

1. Open `Trusted Senders...`.
2. Add the phone number or Apple ID email that is allowed to send prompts.
3. Run `Run Doctor`.
4. Use the permission settings menu items that Doctor asks for.
5. Send `/status` from the trusted sender.
6. Send a normal prompt from the trusted sender.

Fresh installs start with no trusted senders. In that state the bridge can run,
but it ignores inbound Messages until you add at least one trusted sender.

## Menu

The app intentionally stays small. The menu contains the operational controls:

- `Run Doctor`
- `Computer Use Probe`
- `Trusted Senders...`
- `Permission Broker Status`
- `Permission Broker Dry-Run Scan`
- Permission settings shortcuts
- Login helper controls
- `Reset Codex Session`
- `Open Logs`
- `Quit`

`Trusted Senders...` opens a plain native list window with `+` and `-` controls.
Changes save immediately to the runtime config and do not require restarting the
helper.

## Runtime Paths

The Swift bridge preserves the existing runtime locations:

- `~/Library/Application Support/MessagesLLMBridge/`
- `~/Library/Logs/MessagesLLMBridge/`

Important runtime files:

- `config.json`: trusted senders, Codex paths, bridge options.
- `state.json`: active session/job state.
- `messages-bridge-swift.log`: helper logs.

## Permissions

Do not edit TCC databases directly. Use `Run Doctor`, `Computer Use Probe`, and
the menu's System Settings shortcuts.

The bridge may need:

- Full Disk Access: read the local Messages database.
- Automation for Messages: send replies through Messages.
- Automation to `com.openai.sky.CUAService`: run Codex Computer Use when asked.
- Accessibility: allow Codex/Computer Use and the permission broker to operate local UI.
- Screen Recording: allow Computer Use to inspect the screen.

Permissions are not auto-granted by the app. The app opens the relevant System
Settings panes and reports missing permissions through Doctor.

## Control Commands

Send these exact messages from a trusted sender:

- `/status`: compact bridge status.
- `/codex status`: active Codex thread id/link, active job state, progress, and capability status.
- `/codex open`: open the active Codex thread in Codex.app.
- `/codex history`: summarize the last loaded turns from the active Codex thread.

All other text from a trusted sender is treated as a prompt for Codex.

## Development And Validation

Useful development commands:

```sh
swift build
swift test
swift run BridgeCoreSelfTest
swift run BridgeCoreTests
swift run codexmsgctl-swift status
swift run codexmsgctl-swift doctor
./BuildSupport/build-app.zsh
```

The release validation checklist lives in `RELEASE_CHECKLIST.md`.
