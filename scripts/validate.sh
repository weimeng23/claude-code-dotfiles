#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r -d '' json_file; do
  python3 -m json.tool "$json_file" >/dev/null
  echo "json ok: ${json_file#$repo_root/}"
done < <(find "$repo_root" -name '*.json' -type f -print0)

while IFS= read -r -d '' shell_file; do
  bash -n "$shell_file"
  echo "shell ok: ${shell_file#$repo_root/}"
done < <(find "$repo_root" -name '*.sh' -type f -print0)

echo "validation ok"
