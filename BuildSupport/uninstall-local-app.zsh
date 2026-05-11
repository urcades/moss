#!/bin/zsh
set -euo pipefail

DRY_RUN=0
PURGE_STATE=0
APP_DEST="${APP_DEST:-$HOME/Applications/MessagesCodexBridge.app}"
RUNTIME_HOME="${MESSAGES_LLM_BRIDGE_HOME:-$HOME/Library/Application Support/MessagesLLMBridge}"
LOG_DIR="${MESSAGES_LLM_BRIDGE_LOG_DIR:-$HOME/Library/Logs/MessagesLLMBridge}"
HELPER_PLIST="$HOME/Library/LaunchAgents/com.moss.MessagesCodexBridge.Helper.plist"
BROKER_PLIST="$HOME/Library/LaunchAgents/com.moss.MessagesCodexBridge.PermissionBroker.plist"

usage() {
  cat <<'USAGE'
Usage:
  BuildSupport/uninstall-local-app.zsh [--dry-run] [--purge-state]

Default behavior removes installed apps and LaunchAgents while preserving
runtime config, state, and logs. Use --purge-state to remove runtime state and
logs as well.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --purge-state)
      PURGE_STATE=1
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

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

echo "Stopping Messages Codex Bridge services..."
run /bin/launchctl bootout "gui/$(id -u)" "$HELPER_PLIST" 2>/dev/null || true
run /bin/launchctl bootout "gui/$(id -u)" "$BROKER_PLIST" 2>/dev/null || true
run /usr/bin/osascript -e 'tell application id "com.moss.MessagesCodexBridge" to quit' 2>/dev/null || true

echo "Removing installed apps and LaunchAgents..."
run /bin/rm -rf "$APP_DEST"
run /bin/rm -rf "$RUNTIME_HOME/Applications/MessagesCodexBridge.app"
run /bin/rm -f "$HELPER_PLIST"
run /bin/rm -f "$BROKER_PLIST"

if [[ "$PURGE_STATE" -eq 1 ]]; then
  echo "Purging runtime state and logs..."
  run /bin/rm -rf "$RUNTIME_HOME"
  run /bin/rm -rf "$LOG_DIR"
else
  echo "Preserved runtime state and logs:"
  echo "  $RUNTIME_HOME"
  echo "  $LOG_DIR"
fi

echo "Uninstall complete."
