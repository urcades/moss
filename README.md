# Codex Misc Bridge Workspace

The active bridge source for this workspace is:

- `messages-codex-bridge-mac/`

That Swift/macOS bridge is the current implementation path.

Legacy bridge archives and runtime snapshots are intentionally outside this Git repo at:

- `../Codex Misc Archive/`

Useful Swift commands:

```sh
cd messages-codex-bridge-mac
./BuildSupport/check-active-bridge.zsh
swift build
swift run BridgeCoreTests
swift run BridgeCoreSelfTest
swift run codexmsgctl-swift status
swift run codexmsgctl-swift doctor
```
