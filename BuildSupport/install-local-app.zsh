#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DEST="${APP_DEST:-$HOME/Applications/MessagesCodexBridge.app}"
OPEN_APP=1
SAFETY=""
CONFIG_PATH="$HOME/Library/Application Support/MessagesLLMBridge/config.json"

usage() {
  cat <<'USAGE'
Usage:
  BuildSupport/install-local-app.zsh [--safety standard|permissive|preserve] [--no-open]

Safety profiles:
  standard    Recommended. Restricted outgoing attachments and broker auto-clicking off.
  permissive  Personal dogfooding. Full outgoing attachment access and broker auto-clicking on.
  preserve    Keep existing safety settings while migrating/creating runtime config.

Environment:
  APP_DEST    Install destination. Defaults to ~/Applications/MessagesCodexBridge.app.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --safety)
      [[ $# -ge 2 ]] || { echo "--safety requires standard, permissive, or preserve." >&2; exit 2; }
      SAFETY="$2"
      shift 2
      ;;
    --no-open)
      OPEN_APP=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

choose_safety() {
  if [[ -n "$SAFETY" ]]; then
    return
  fi
  if [[ ! -t 0 ]]; then
    SAFETY="standard"
    return
  fi

  echo "Choose a safety profile for runtime config:"
  echo "  1) standard    Recommended for source-build installs."
  echo "                 Restricted outgoing attachments; broker auto-clicking off."
  echo "  2) permissive  Personal dogfooding."
  echo "                 Full outgoing attachment access; broker auto-clicking on."
  if [[ -f "$CONFIG_PATH" ]]; then
    echo "  3) preserve    Keep existing safety settings."
  fi
  echo
  read "choice?Safety profile [1]: "
  case "${choice:-1}" in
    1|standard|s|S)
      SAFETY="standard"
      ;;
    2|permissive|p|P)
      SAFETY="permissive"
      ;;
    3|preserve|preserve-existing)
      if [[ -f "$CONFIG_PATH" ]]; then
        SAFETY="preserve"
      else
        echo "No existing config found to preserve." >&2
        exit 2
      fi
      ;;
    *)
      echo "Unknown safety profile choice: $choice" >&2
      exit 2
      ;;
  esac
}

case "$SAFETY" in
  ""|standard|permissive|preserve) ;;
  *)
    echo "Unknown safety profile: $SAFETY" >&2
    exit 2
    ;;
esac

choose_safety

cd "$ROOT"

echo "Building Messages Codex Bridge..."
"$ROOT/BuildSupport/build-app.zsh"
APP_BUILT="$ROOT/.build/app/MessagesCodexBridge.app"

echo "Applying safety profile: $SAFETY"
swift run codexmsgctl-swift configure --safety "$SAFETY"

echo "Quitting any running menubar app..."
/usr/bin/osascript -e 'tell application id "com.moss.MessagesCodexBridge" to quit' >/dev/null 2>&1 || true
for _ in {1..20}; do
  if ! /usr/bin/pgrep -f "MessagesCodexBridge.app/Contents/MacOS/MessagesCodexBridge" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

echo "Installing app to $APP_DEST"
mkdir -p "$(dirname "$APP_DEST")"
rm -rf "$APP_DEST"
/usr/bin/ditto "$APP_BUILT" "$APP_DEST"

if [[ "$OPEN_APP" -eq 1 ]]; then
  echo "Opening $APP_DEST"
  /usr/bin/open "$APP_DEST"
else
  echo "Skipping app launch (--no-open)."
fi

cat <<EOF

Installed Messages Codex Bridge.

Next steps:
  1. Open the menubar app menu.
  2. Add a sender in Trusted Senders...
  3. Run Doctor.
  4. Send /status from the trusted sender.
EOF
