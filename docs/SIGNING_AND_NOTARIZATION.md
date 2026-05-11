# Signing And Notarization

This project supports source builds and Developer ID distribution. Source builds
can use local or ad hoc signing. Public binary distribution should use a
Developer ID Application certificate, hardened runtime, notarization, and a
stapled app ticket.

## 1. Confirm Your Developer ID Certificate

Open Keychain Access and confirm your Developer ID Application certificate is
installed, or run:

```sh
security find-identity -p codesigning -v
```

Look for an identity like:

```text
Developer ID Application: Your Name (TEAMID)
```

## 2. Store Notary Credentials

Create an app-specific password for your Apple ID, then store credentials in
Keychain:

```sh
xcrun notarytool store-credentials moss-notary
```

When prompted, enter your Apple ID, team ID, and app-specific password. The
profile name `moss-notary` is only stored locally in Keychain.

## 3. Build, Sign, Notarize, And Zip

From the repository root:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="moss-notary" \
BuildSupport/package-release.zsh
```

The script:

- builds a release app,
- signs the app, helper, and permission broker with hardened runtime,
- uploads a zip to Apple notarization,
- staples the accepted ticket to the app,
- validates with `stapler` and `spctl`,
- writes the final zip to `.build/dist/`.

## 4. Attach To A GitHub Release

After the script succeeds, attach the final zip to the release:

```sh
gh release upload v0.3.0 .build/dist/MessagesCodexBridge-0.3.0.zip
```

## Troubleshooting

- `SIGN_IDENTITY is required`: run `security find-identity -p codesigning -v`
  and copy the full Developer ID Application identity.
- `No Keychain password item found`: rerun `xcrun notarytool store-credentials`.
- `The signature does not include a secure timestamp`: confirm you are signing
  with Developer ID, not the local development identity.
- Gatekeeper still blocks the app: rerun `xcrun stapler validate` and
  `spctl -a -vv --type execute`.
