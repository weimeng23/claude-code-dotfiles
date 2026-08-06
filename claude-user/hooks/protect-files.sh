#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

json_file_path() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '
      (.tool_input.file_path // "") as $file
      | if $file != "" then $file else (.tool_input.notebook_path // "") end
    '
  elif command -v python3 >/dev/null 2>&1; then
    JSON_INPUT="$input" python3 - <<'PY'
import json
import os

try:
    data = json.loads(os.environ.get("JSON_INPUT", "{}"))
except json.JSONDecodeError:
    data = {}

tool_input = data.get("tool_input", {})
print(tool_input.get("file_path") or tool_input.get("notebook_path", ""))
PY
  fi
}

file="$(json_file_path)"

if [[ -z "$file" ]]; then
  exit 0
fi

case "$file" in
  *.env|*.env.*|*/.env|*/.env.*)
    echo "Blocked edit/write to env file: $file" >&2
    exit 2
    ;;
  *id_rsa*|*id_ed25519*|*.pem|*.key|*.crt|*.token|*.secret)
    echo "Blocked edit/write to sensitive file: $file" >&2
    exit 2
    ;;
  */.git/*)
    echo "Blocked edit/write inside .git directory: $file" >&2
    exit 2
    ;;
  */secrets/*|*/secret/*|*/credentials/*|*/private/*)
    echo "Blocked edit/write to secrets/credentials path: $file" >&2
    exit 2
    ;;
esac

exit 0
