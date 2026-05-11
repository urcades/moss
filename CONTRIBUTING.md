# Contributing

Thanks for taking a look at Messages Codex Bridge.

## Development Setup

```sh
git clone https://github.com/urcades/moss.git
cd moss
./BuildSupport/install-local-app.zsh --safety standard
```

## Validation

Run these before opening a PR:

```sh
zsh -n BuildSupport/*.zsh
swift test
swift run BridgeCoreSelfTest
swift run BridgeCoreTests
./BuildSupport/build-app.zsh
swift run codexmsgctl-swift doctor
```

Doctor can report missing macOS permissions on a fresh machine. Include that
context in issues or PRs when relevant.

## Useful Runtime Paths

```text
~/Library/Application Support/MessagesLLMBridge/
~/Library/Logs/MessagesLLMBridge/
```

## Pull Requests

Keep PRs focused. Include the commands you ran, any Doctor failures, and whether
the change affects the menu-bar app, helper, permission broker, installer, or
runtime config.
