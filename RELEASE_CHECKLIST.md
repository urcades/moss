# Release Checklist

Manual validation for the v0.2.0 source-build release.

## Automated Checks

Run from the repository root:

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
3. Confirm the menu header shows `Messages Codex Bridge 0.2.0`.
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
16. Confirm uninstall instructions in `docs/UNINSTALL.md` match the installed
    files and LaunchAgent labels.

## Release Steps

After the automated checks and smoke test are green:

1. Ensure `main` is up to date and clean.
2. Push `main`.
3. Confirm the GitHub repo description and topics are set.
4. Create the annotated tag:

```sh
git tag -a v0.2.0 -m "Messages Codex Bridge v0.2.0"
git push origin v0.2.0
```

5. Create a GitHub release from `v0.2.0` with source-build instructions.

## Deferred Work

- Signed and notarized zipped app distribution.
- Custom app icon and final bundle artwork.
