# Release Checklist

Manual validation for the v0.1.0 source-build release candidate.

## Automated Checks

Run from `messages-codex-bridge-mac`:

```sh
swift test
swift run BridgeCoreSelfTest
swift run BridgeCoreTests
zsh -n BuildSupport/install-local-app.zsh
swift run codexmsgctl-swift configure --help
./BuildSupport/build-app.zsh
swift run codexmsgctl-swift doctor
```

All commands should complete successfully. Doctor may report missing macOS
permissions on a fresh machine; grant the requested permissions and rerun Doctor
before cutting a release.

## App Smoke Test

1. Open the built app:

```sh
./BuildSupport/install-local-app.zsh --safety standard
```

2. Confirm the menubar process runs from `~/Applications/MessagesCodexBridge.app`.
3. Confirm the menu header shows `Messages Codex Bridge 0.1.0`.
4. Open `Trusted Senders...`.
5. Add a test sender.
6. Remove the test sender, or replace it with the real trusted sender.
7. Close the Trusted Senders window and confirm the menu-bar app stays alive.
8. Confirm the selected safety profile in config:

```sh
swift run codexmsgctl-swift configure --preserve-safety
```

For `standard`, outgoing attachments should be `restricted` and permission
broker auto-clicking should be `off`.

9. Confirm status reports the trusted sender list:

```sh
swift run codexmsgctl-swift status
```

10. Send `/status` from a trusted sender and confirm the bridge replies.
11. Send a normal prompt from a trusted sender and confirm Codex replies.
12. Quit and reopen the menu-bar app.
13. Run Doctor again and confirm the bridge is still healthy.
14. Confirm helper and broker LaunchAgents remain loaded:

```sh
launchctl print "gui/$(id -u)/com.moss.MessagesCodexBridge.Helper"
launchctl print "gui/$(id -u)/com.moss.MessagesCodexBridge.PermissionBroker"
```

15. After a logout/login or restart, confirm the helper is still loaded and
    `/status` still works.

## Release Steps

After the automated checks and smoke test are green:

1. Push `experiments/app-server-exec`.
2. Open a PR into `main` titled `Promote Swift bridge v0.1.0 baseline`.
3. Merge the PR.
4. Update local `main`.
5. Create the annotated tag:

```sh
git tag -a v0.1.0 -m "Messages Codex Bridge v0.1.0"
git push origin v0.1.0
```

## Deferred Work

- Signed and notarized zipped app distribution.
- Custom app icon and final bundle artwork.
