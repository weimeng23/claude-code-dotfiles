#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$repo_root/claude-user/skills"
package="${1:-}"
skill_names=("${@:2}")

usage() {
  echo "usage: $0 <owner/repo-or-url> <skill-name> [skill-name ...]" >&2
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

seen_names=" "
for skill_name in "${skill_names[@]}"; do
  if [[ ! "$skill_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ || ${#skill_name} -gt 64 ]]; then
    echo "error: invalid skill name: $skill_name" >&2
    exit 2
  fi

  if [[ "$seen_names" == *" $skill_name "* ]]; then
    echo "error: duplicate skill name: $skill_name" >&2
    exit 2
  fi
  seen_names+="$skill_name "

  target_dir="$skills_dir/$skill_name"
  if [[ -e "$target_dir" || -L "$target_dir" ]]; then
    echo "error: skill already exists: ${target_dir#$repo_root/}" >&2
    exit 1
  fi
done

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx is required to import skills" >&2
  exit 1
fi

mkdir -p "$repo_root/tmp" "$skills_dir"
work_dir="$(mktemp -d "$repo_root/tmp/skill-import.XXXXXX")"
copied_dirs=()
completed=false

cleanup() {
  local status=$?

  rm -rf "$work_dir"
  if [[ "$completed" != true ]]; then
    for copied_dir in "${copied_dirs[@]}"; do
      rm -rf "$copied_dir"
    done
  fi

  return "$status"
}

trap cleanup EXIT

(
  cd "$work_dir"
  npx --yes skills add "$package" \
    --skill "${skill_names[@]}" \
    --agent claude-code \
    --copy \
    -y
)

source_dirs=()
for skill_name in "${skill_names[@]}"; do
  source_dir="$work_dir/.agents/skills/$skill_name"
  if [[ ! -d "$source_dir" ]]; then
    source_dir="$work_dir/.claude/skills/$skill_name"
  fi

  if [[ ! -d "$source_dir" || ! -f "$source_dir/SKILL.md" ]]; then
    echo "error: imported skill not found: $skill_name" >&2
    exit 1
  fi

  source_dirs+=("$source_dir")
done

for index in "${!skill_names[@]}"; do
  target_dir="$skills_dir/${skill_names[$index]}"
  copied_dirs+=("$target_dir")
  cp -R "${source_dirs[$index]}" "$target_dir"
done

if ! "$repo_root/scripts/validate.sh"; then
  echo "error: imported skills failed validation and were removed" >&2
  exit 1
fi

completed=true
for skill_name in "${skill_names[@]}"; do
  echo "imported: $package@$skill_name -> claude-user/skills/$skill_name"
done
echo "next: review the imported files, then run scripts/install-skills.sh"
