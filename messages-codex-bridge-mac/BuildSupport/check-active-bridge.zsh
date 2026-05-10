#!/bin/zsh
set -euo pipefail

repo_root="$(cd -- "$(dirname "$0")/.." && pwd)"
workspace_root="$(cd -- "$repo_root/.." && pwd)"

failures=0

if [[ ! -d "$workspace_root/messages-codex-bridge-mac/Sources/BridgeCore" ]]; then
  print -u2 "Missing active Swift bridge source at messages-codex-bridge-mac/Sources/BridgeCore"
  failures=1
fi

while IFS= read -r file; do
  if grep -E '(^|[[:space:]/])messages-(codex-bridge-v2|llm-bridge-node-appserver)([[:space:]/]|$)' "$file" >/dev/null; then
    if ! grep -E 'archive/old-bridges/messages-(codex-bridge-v2|llm-bridge-node-appserver)' "$file" >/dev/null; then
      print -u2 "Archived JavaScript bridge referenced outside archive context: ${file#$workspace_root/}"
      failures=1
    fi
  fi
done < <(find "$workspace_root" \
  -path "$workspace_root/.git" -prune -o \
  -path "$workspace_root/messages-codex-bridge-mac/.build" -prune -o \
  -path "$workspace_root/archive" -prune -o \
  -type f \( -name '*.md' -o -name '*.zsh' -o -name '*.sh' -o -name 'Package.swift' \) -print)

if [[ "$failures" != 0 ]]; then
  exit "$failures"
fi

print "Active bridge check passed: messages-codex-bridge-mac is the only runnable bridge path."
