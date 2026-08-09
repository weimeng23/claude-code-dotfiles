#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$repo_root/claude-user/skills"
package="${1:-}"
skill_name="${2:-}"

usage() {
  echo "usage: $0 <owner/repo-or-url> <skill-name>" >&2
}

if [[ $# -ne 2 ]]; then
  usage
  exit 2
fi

if [[ ! "$skill_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ || ${#skill_name} -gt 64 ]]; then
  echo "error: invalid skill name: $skill_name" >&2
  exit 2
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx is required to import skills" >&2
  exit 1
fi

target_dir="$skills_dir/$skill_name"
if [[ -e "$target_dir" || -L "$target_dir" ]]; then
  echo "error: skill already exists: ${target_dir#$repo_root/}" >&2
  exit 1
fi

mkdir -p "$repo_root/tmp" "$skills_dir"
work_dir="$(mktemp -d "$repo_root/tmp/skill-import.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

(
  cd "$work_dir"
  npx --yes skills add "$package" \
    --skill "$skill_name" \
    --agent claude-code \
    --copy \
    -y
)

source_dir="$work_dir/.agents/skills/$skill_name"
if [[ ! -d "$source_dir" ]]; then
  source_dir="$work_dir/.claude/skills/$skill_name"
fi

if [[ ! -d "$source_dir" || ! -f "$source_dir/SKILL.md" ]]; then
  echo "error: imported skill not found: $skill_name" >&2
  exit 1
fi

cp -R "$source_dir" "$target_dir"

if ! "$repo_root/scripts/validate.sh"; then
  rm -rf "$target_dir"
  echo "error: imported skill failed validation and was removed" >&2
  exit 1
fi

echo "imported: $package@$skill_name -> ${target_dir#$repo_root/}"
echo "next: review the imported files, then run scripts/install-skills.sh"
