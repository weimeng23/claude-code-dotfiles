#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-}"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 claude|codex|all" >&2
  exit 2
fi

case "$target" in
  claude|codex)
    exec "$script_dir/install.sh" --skills-only "$target"
    ;;
  all)
    "$script_dir/install.sh" --skills-only claude
    "$script_dir/install.sh" --skills-only codex
    ;;
  *)
    echo "usage: $0 claude|codex|all" >&2
    exit 2
    ;;
esac
