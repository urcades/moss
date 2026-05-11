# Security Policy

## Supported Versions

Only the latest tagged source-build release is supported for security fixes.

## Reporting A Vulnerability

Open a private security advisory on GitHub if available. If that is not
available, open an issue with minimal reproduction details and omit secrets,
phone numbers, Apple IDs, message contents, and local file paths that should
stay private.

## Local Automation Model

Messages Codex Bridge is a local macOS automation tool. It can read the local
Messages database after Full Disk Access is granted, send replies through
Messages after Automation is granted, and invoke Codex for prompts received
from trusted senders.

The permission broker is disabled in the standard safety profile. In permissive
mode it can auto-click trusted local macOS permission prompts. Only enable
permissive mode on machines where that matches your personal trust model.
