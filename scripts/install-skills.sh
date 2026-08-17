#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/log.sh"
target="${1:-}"

if [[ $# -ne 1 ]]; then
  log_warn "usage: $0 claude|codex|all"
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
    log_warn "usage: $0 claude|codex|all"
    exit 2
    ;;
esac
