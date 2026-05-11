#!/bin/zsh
set -euo pipefail

repo_root="$(cd -- "$(dirname "$0")/.." && pwd)"

failures=0

if [[ ! -d "$repo_root/Sources/BridgeCore" ]]; then
  print -u2 "Missing active Swift bridge source at Sources/BridgeCore"
  failures=1
fi

while IFS= read -r file; do
  if grep -E '(^|[[:space:]/])messages-(codex-bridge-v2|llm-bridge-node-appserver)([[:space:]/]|$)' "$file" >/dev/null; then
    if ! grep -E 'archive/old-bridges/messages-(codex-bridge-v2|llm-bridge-node-appserver)' "$file" >/dev/null; then
      print -u2 "Archived JavaScript bridge referenced outside archive context: ${file#$repo_root/}"
      failures=1
    fi
  fi
done < <(find "$repo_root" \
  -path "$repo_root/.git" -prune -o \
  -path "$repo_root/.build" -prune -o \
  -path "$repo_root/archive" -prune -o \
  -type f \( -name '*.md' -o -name '*.zsh' -o -name '*.sh' -o -name 'Package.swift' \) -print)

if [[ "$failures" != 0 ]]; then
  exit "$failures"
fi

print "Active bridge check passed: repository root is the runnable Swift bridge path."
