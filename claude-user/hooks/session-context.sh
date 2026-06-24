#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

json_cwd() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.cwd // empty'
  elif command -v python3 >/dev/null 2>&1; then
    JSON_INPUT="$input" python3 - <<'PY'
import json
import os

try:
    data = json.loads(os.environ.get("JSON_INPUT", "{}"))
except json.JSONDecodeError:
    data = {}

print(data.get("cwd", ""))
PY
  fi
}

cwd="$(json_cwd)"

if [[ -n "$cwd" && -d "$cwd" ]]; then
  cd "$cwd"
fi

echo "Claude Code session context:"
echo

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Git branch:"
  git branch --show-current 2>/dev/null || true

  echo
  echo "Git status:"
  git status --short 2>/dev/null | head -80 || true

  echo
  echo "Recent commits:"
  git log --oneline -5 2>/dev/null || true
else
  echo "Not inside a git repository."
fi

echo
if [[ -f CLAUDE.md ]]; then
  echo "Project CLAUDE.md found."
fi

if [[ -f AGENTS.md ]]; then
  echo "Project AGENTS.md found."
fi
