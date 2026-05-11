# Privacy And Security FAQ

## What does the bridge read?

After Full Disk Access is granted, the helper reads the local Messages database
to find new inbound messages from trusted senders.

## What does the bridge send?

Prompts from trusted senders are sent to Codex through the local Codex app-server
CLI. Replies are sent back through Apple Messages.

## Who can trigger prompts?

Only handles listed in `Trusted Senders...` are accepted. Fresh installs start
with no trusted senders.

## What is stored locally?

Runtime config, trusted senders, state, permission-broker status, and logs are
stored under:

```text
~/Library/Application Support/MessagesLLMBridge/
~/Library/Logs/MessagesLLMBridge/
```

## What is the standard safety profile?

`standard` restricts outgoing attachments to normal image/PDF files under home
or temp paths and disables permission broker auto-clicking.

## What is the permissive safety profile?

`permissive` allows outgoing attachment access broadly and enables broad
permission broker auto-clicking. Use it only on a trusted personal Mac.

## Are macOS permissions granted automatically?

No. The app opens System Settings and reports missing permissions, but macOS
privacy grants must still be approved by the user.
