# Privacy And Security FAQ

## What does the bridge read?

After Full Disk Access is granted, the helper reads the local Messages database
to find new inbound messages from trusted senders. For those messages, it also
reads attachment metadata such as filenames, MIME/UTI values, transfer names,
and local attachment paths when present.

## What does the bridge send?

Prompts from trusted senders are sent to Codex through the local Codex app-server
CLI with Codex approval prompts disabled and broad local sandbox access. Image
attachments from trusted senders are passed to Codex as local image inputs when
the files are available; other attachments are listed in the prompt with local
paths when known. Replies are sent back through Apple Messages.

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

## Does standard mode stop the permission broker process?

No. The broker LaunchAgent may still run so it can report status and dry-run
observations, but standard mode disables auto-clicking.

## Are macOS permissions granted automatically?

No. The app opens System Settings and reports missing permissions, but macOS
privacy grants must still be approved by the user.
