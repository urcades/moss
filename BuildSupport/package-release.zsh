#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
VERSION="${VERSION:-}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
DIST_DIR="$ROOT/.build/dist"
APP="$ROOT/.build/app/MessagesCodexBridge.app"

usage() {
  cat <<'USAGE'
Usage:
  SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE="moss-notary" BuildSupport/package-release.zsh

Environment:
  SIGN_IDENTITY     Required Developer ID Application signing identity.
  NOTARY_PROFILE    Required notarytool keychain profile name.
  VERSION           Optional release version. Defaults to app Info.plist version.
  CONFIGURATION     Optional Swift build configuration. Defaults to release.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "SIGN_IDENTITY is required. Run: security find-identity -p codesigning -v" >&2
  exit 2
fi

if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "NOTARY_PROFILE is required. Create one with: xcrun notarytool store-credentials moss-notary" >&2
  exit 2
fi

cd "$ROOT"

echo "Building release app with Developer ID signing..."
CONFIGURATION="$CONFIGURATION" SIGN_IDENTITY="$SIGN_IDENTITY" HARDENED_RUNTIME=1 "$ROOT/BuildSupport/build-app.zsh"

if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")"
fi

mkdir -p "$DIST_DIR"
SUBMIT_ZIP="$DIST_DIR/MessagesCodexBridge-$VERSION-submit.zip"
FINAL_ZIP="$DIST_DIR/MessagesCodexBridge-$VERSION.zip"
rm -f "$SUBMIT_ZIP" "$FINAL_ZIP"

echo "Verifying code signatures..."
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
/usr/sbin/spctl -a -vv --type execute "$APP" || true

echo "Creating notarization upload zip..."
/usr/bin/ditto -c -k --keepParent "$APP" "$SUBMIT_ZIP"

echo "Submitting to Apple notarization service..."
/usr/bin/xcrun notarytool submit "$SUBMIT_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "Stapling notarization ticket..."
/usr/bin/xcrun stapler staple "$APP"
/usr/bin/xcrun stapler validate "$APP"

echo "Validating Gatekeeper assessment..."
/usr/sbin/spctl -a -vv --type execute "$APP"

echo "Creating final stapled release zip..."
/usr/bin/ditto -c -k --keepParent "$APP" "$FINAL_ZIP"

echo "Release artifact: $FINAL_ZIP"
