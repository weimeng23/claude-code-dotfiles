#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/claude-user"
target_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$target_dir/backups/dotfiles-$timestamp"

backup_file() {
  local target="$1"
  local rel="${target#$target_dir/}"
  local backup="$backup_dir/$rel"

  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$(dirname "$backup")"
    cp -P "$target" "$backup"
    echo "backup: $target -> $backup"
  fi
}

check_target() {
  local source="$1"
  local target="$2"

  if [[ "$(basename "$source")" == ".gitkeep" ]]; then
    return
  fi

  if [[ -d "$target" ]]; then
    echo "error: install target is a directory: $target" >&2
    return 1
  fi
}

install_file() {
  local source="$1"
  local target="$2"
  local temp

  if [[ "$(basename "$source")" == ".gitkeep" ]]; then
    return
  fi

  mkdir -p "$(dirname "$target")"

  check_target "$source" "$target"

  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    echo "unchanged: $target"
    return
  fi

  backup_file "$target"
  temp="$(mktemp "${target}.tmp.XXXXXX")"
  if ! cp -p "$source" "$temp" || ! mv -f "$temp" "$target"; then
    rm -f "$temp"
    return 1
  fi
  echo "installed: $target"
}

check_tree_targets() {
  local source_tree="$1"
  local target_tree="$2"

  [[ -d "$source_tree" ]] || return

  while IFS= read -r -d '' source_file; do
    local rel="${source_file#$source_tree/}"
    check_target "$source_file" "$target_tree/$rel"
  done < <(find "$source_tree" -type f -print0)
}

install_tree() {
  local source_tree="$1"
  local target_tree="$2"

  [[ -d "$source_tree" ]] || return

  while IFS= read -r -d '' source_file; do
    local rel="${source_file#$source_tree/}"
    install_file "$source_file" "$target_tree/$rel"
  done < <(find "$source_tree" -type f -print0)
}

"$repo_root/scripts/validate.sh"

if [[ -e "$target_dir" && ! -d "$target_dir" ]]; then
  echo "error: config target is not a directory: $target_dir" >&2
  exit 1
fi

check_target "$source_dir/CLAUDE.md" "$target_dir/CLAUDE.md"
check_target "$source_dir/settings.json" "$target_dir/settings.json"
check_tree_targets "$source_dir/agents" "$target_dir/agents"
check_tree_targets "$source_dir/skills" "$target_dir/skills"
check_tree_targets "$source_dir/hooks" "$target_dir/hooks"

mkdir -p "$target_dir"

install_file "$source_dir/CLAUDE.md" "$target_dir/CLAUDE.md"
install_file "$source_dir/settings.json" "$target_dir/settings.json"
install_tree "$source_dir/agents" "$target_dir/agents"
install_tree "$source_dir/skills" "$target_dir/skills"
install_tree "$source_dir/hooks" "$target_dir/hooks"

echo "done: installed personal Claude Code config to $target_dir"
