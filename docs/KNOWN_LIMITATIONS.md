# Known Limitations

- Binary distribution is a notarized zip, not a polished DMG.
- Notarized releases require the maintainer to run the local packaging script.
- Setup still requires macOS privacy permissions through System Settings.
- Apple Messages must already be signed in and healthy on the Mac.
- Codex.app and its bundled CLI are required.
- Trusted senders are allowlisted locally; there is no remote pairing flow.
- The standard safety profile disables permission broker auto-clicking.
- The permissive safety profile is intended for personal dogfooding on a trusted Mac.
