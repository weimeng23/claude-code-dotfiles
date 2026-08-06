#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/claude-user"

validate_json() {
  local json_file="$1"

  if command -v jq >/dev/null 2>&1; then
    jq empty "$json_file"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$json_file" >/dev/null
  else
    echo "error: JSON validation requires jq or python3" >&2
    return 1
  fi
}

while IFS= read -r -d '' json_file; do
  validate_json "$json_file"
  echo "json ok: ${json_file#$repo_root/}"
done < <(find "$source_dir" -name '*.json' -type f -print0)

while IFS= read -r -d '' shell_file; do
  bash -n "$shell_file"
  echo "shell ok: ${shell_file#$repo_root/}"
done < <(find "$source_dir" "$repo_root/scripts" -name '*.sh' -type f -print0)

echo "validation ok"
