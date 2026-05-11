#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
LOCAL_SIGNING_IDENTITY="${LOCAL_SIGNING_IDENTITY:-Messages Codex Bridge Local Code Signing}"
HARDENED_RUNTIME="${HARDENED_RUNTIME:-0}"
ICON_SOURCE="$ROOT/Resources/Icon/MessagesCodexBridge.icns"
APP="$ROOT/.build/app/MessagesCodexBridge.app"
HELPER="$APP/Contents/Library/LoginItems/MessagesCodexBridgeHelper.app"
BROKER="$APP/Contents/Library/LoginItems/MessagesCodexPermissionBroker.app"

if [[ -z "$SIGN_IDENTITY" ]]; then
  if security find-identity -v -p codesigning -s "$LOCAL_SIGNING_IDENTITY" 2>/dev/null | grep -q 'valid identities found'; then
    SIGN_IDENTITY="$LOCAL_SIGNING_IDENTITY"
  else
    SIGN_IDENTITY="-"
  fi
fi

cd "$ROOT"
swift build -c "$CONFIGURATION"

BIN_DIR="$ROOT/.build/$CONFIGURATION"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$HELPER/Contents/MacOS" "$BROKER/Contents/MacOS"
mkdir -p "$APP/Contents/Library/LoginItems"

cp "$BIN_DIR/MessagesCodexBridgeApp" "$APP/Contents/MacOS/MessagesCodexBridge"
cp "$BIN_DIR/MessagesCodexBridgeHelper" "$HELPER/Contents/MacOS/MessagesCodexBridgeHelper"
cp "$BIN_DIR/MessagesCodexPermissionBroker" "$BROKER/Contents/MacOS/MessagesCodexPermissionBroker"
if [[ -f "$ICON_SOURCE" ]]; then
  cp "$ICON_SOURCE" "$APP/Contents/Resources/MessagesCodexBridge.icns"
fi

/usr/libexec/PlistBuddy -c "Clear dict" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.moss.MessagesCodexBridge" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Messages Codex Bridge" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string MessagesCodexBridge" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string MessagesCodexBridge" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.3.0" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 3" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSAppleEventsUsageDescription string Messages Codex Bridge sends Apple Events to Messages and Codex Computer Use at your request." "$APP/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Clear dict" "$HELPER/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.moss.MessagesCodexBridge.Helper" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Messages Codex Bridge Helper" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string MessagesCodexBridgeHelper" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.3.0" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 3" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$HELPER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSAppleEventsUsageDescription string Messages Codex Bridge Helper sends Apple Events to Messages and Codex Computer Use at your request." "$HELPER/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Clear dict" "$BROKER/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.moss.MessagesCodexBridge.PermissionBroker" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Messages Codex Permission Broker" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string MessagesCodexPermissionBroker" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.3.0" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 3" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$BROKER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSAppleEventsUsageDescription string Messages Codex Permission Broker handles local macOS permission prompts for bridge-triggered Codex automation at your request." "$BROKER/Contents/Info.plist"

SIGN_ARGS=(--force --deep --sign "$SIGN_IDENTITY")
if [[ "$HARDENED_RUNTIME" == "1" ]]; then
  SIGN_ARGS+=(--options runtime)
fi

/usr/bin/codesign "${SIGN_ARGS[@]}" "$HELPER"
/usr/bin/codesign "${SIGN_ARGS[@]}" "$BROKER"
/usr/bin/codesign "${SIGN_ARGS[@]}" "$APP"

echo "$APP"
