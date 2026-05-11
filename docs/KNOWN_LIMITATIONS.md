# Known Limitations

- Source build is the supported public install path.
- Notarized zip packaging exists for maintainers, but binary releases are not
  the default public artifact yet.
- Setup still requires macOS privacy permissions through System Settings.
- Apple Messages must already be signed in and healthy on the Mac.
- Codex.app and its bundled CLI are required.
- Trusted senders are allowlisted locally; there is no remote pairing flow.
- Trusted senders can trigger broad local Codex automation; use the allowlist
  only for people you trust with that access.
- The standard safety profile disables permission broker auto-clicking.
- The permissive safety profile is intended for personal dogfooding on a trusted Mac.
