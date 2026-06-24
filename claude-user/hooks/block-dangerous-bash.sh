#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

json_command() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.tool_input.command // ""'
  elif command -v python3 >/dev/null 2>&1; then
    JSON_INPUT="$input" python3 - <<'PY'
import json
import os

try:
    data = json.loads(os.environ.get("JSON_INPUT", "{}"))
except json.JSONDecodeError:
    data = {}

print(data.get("tool_input", {}).get("command", ""))
PY
  fi
}

cmd="$(json_command)"

if [[ -z "$cmd" ]]; then
  exit 0
fi

if echo "$cmd" | grep -Eiq '(^|[ ;|&])rm[[:space:]]+-rf[[:space:]]+(/|~|\$HOME|\*)'; then
  echo "Blocked dangerous command: rm -rf on root/home/wildcard path." >&2
  exit 2
fi

if echo "$cmd" | grep -Eiq 'git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'; then
  echo "Blocked dangerous git destructive command: $cmd" >&2
  exit 2
fi

if echo "$cmd" | grep -Eiq 'chmod[[:space:]]+-R[[:space:]]+777|chown[[:space:]]+-R'; then
  echo "Blocked dangerous permission ownership command: $cmd" >&2
  exit 2
fi

if echo "$cmd" | grep -Eiq '(curl|wget).*\|[[:space:]]*(sh|bash|zsh)'; then
  echo "Blocked pipe-to-shell command: $cmd" >&2
  exit 2
fi

if echo "$cmd" | grep -Eiq 'sudo[[:space:]]+(rm|chmod|chown|dd|mkfs|mount|umount|reboot|shutdown)'; then
  echo "Blocked risky sudo command: $cmd" >&2
  exit 2
fi

exit 0
