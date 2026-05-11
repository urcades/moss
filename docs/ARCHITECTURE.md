# Architecture

Messages Codex Bridge is a small native macOS app plus background helpers.

## Menu-Bar App

`MessagesCodexBridge.app` owns the visible menu-bar UI. It lets users run
Doctor, manage trusted senders, open permission settings, inspect logs, and
start helper services from the currently running app bundle.

## Helper

`MessagesCodexBridgeHelper.app` runs as a user LaunchAgent. It polls the local
Messages database, filters inbound messages by trusted sender, batches nearby
messages, sends prompts to Codex, and replies through Messages.

## Permission Broker

`MessagesCodexPermissionBroker.app` is a separate user LaunchAgent. In the
standard safety profile it is disabled for auto-clicking. In permissive mode it
can handle trusted macOS permission prompts for bridge-triggered automation.

## Codex Backend

The bridge uses the Codex app-server protocol through:

```sh
/Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://
```

It starts or resumes Codex threads, sends turns, names new threads from message
text, reads thread history for `/codex history`, and reports app-server
capabilities through Doctor and `/status`.

Bridge-started Codex turns use approval prompts disabled and broad local sandbox
access. The trusted sender allowlist is therefore the main remote-trigger trust
boundary.

## Runtime State

Runtime config and state live outside the repository:

```text
~/Library/Application Support/MessagesLLMBridge/
~/Library/Logs/MessagesLLMBridge/
```

Important files:

- `config.json`: trusted senders, Codex command/cwd, safety profile, broker config.
- `state/state.json`: processed Messages cursor, pending batch, active Codex job, session id.
- `messages-bridge-swift.log`: helper logs.
- `state/permission-broker/`: permission broker status and event log.

## Install Shape

The source-build installer copies the app to:

```text
~/Applications/MessagesCodexBridge.app
```

On launch, the app copies the running bundle into the runtime app-support
directory and registers LaunchAgents that point at that stable runtime copy.
