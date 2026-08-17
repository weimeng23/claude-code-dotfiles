#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/log.sh"
source_dir="$repo_root/claude-user"

validate_json() {
  local json_file="$1"

  if command -v jq >/dev/null 2>&1; then
    jq empty "$json_file"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$json_file" >/dev/null
  else
    log_err "error: JSON validation requires jq or python3"
    return 1
  fi
}

validate_skills() {
  local skills_dir="$source_dir/skills"
  local entry entry_name skill_file name nested_link

  if [[ -L "$skills_dir" ]]; then
    log_err "error: skills directory must not be a symbolic link: ${skills_dir#$repo_root/}"
    return 1
  fi

  if [[ ! -e "$skills_dir" ]]; then
    return 0
  fi

  if [[ ! -d "$skills_dir" ]]; then
    log_err "error: skills path is not a directory: ${skills_dir#$repo_root/}"
    return 1
  fi

  while IFS= read -r -d '' entry; do
    entry_name="$(basename "$entry")"

    if [[ -L "$entry" ]]; then
      log_err "error: symbolic links are not allowed in ${entry#$repo_root/}"
      return 1
    fi

    if [[ ! -d "$entry" ]]; then
      if [[ "$entry_name" == ".gitkeep" ]]; then
        continue
      fi
      log_err "error: unexpected file in skills directory: ${entry#$repo_root/}"
      return 1
    fi

    if [[ "$entry_name" == .* ]]; then
      log_err "error: hidden skill directories are not allowed: ${entry#$repo_root/}"
      return 1
    fi

    skill_file="$entry/SKILL.md"

    if [[ -L "$skill_file" || ! -f "$skill_file" ]]; then
      log_err "error: missing regular SKILL.md in ${entry#$repo_root/}"
      return 1
    fi

    if ! awk '
      {
        line = $0
        sub(/\r$/, "", line)
      }
      NR == 1 && line == "---" { opened = 1; next }
      opened && line == "---" { closed = 1; exit }
      END { exit !(opened && closed) }
    ' "$skill_file"; then
      log_err "error: invalid frontmatter in ${skill_file#$repo_root/}"
      return 1
    fi

    if ! name="$(awk '
      {
        line = $0
        sub(/\r$/, "", line)
      }
      NR == 1 && line == "---" { in_frontmatter = 1; next }
      in_frontmatter && line == "---" { exit }
      in_frontmatter && line ~ /^name:[[:space:]]+/ {
        count++
        sub(/^name:[[:space:]]+/, "", line)
        value = line
      }
      END {
        if (count != 1) {
          exit 1
        }
        print value
      }
    ' "$skill_file")"; then
      log_err "error: SKILL.md must contain exactly one top-level name in ${skill_file#$repo_root/}"
      return 1
    fi

    case "$name" in
      \"*\")
        name="${name#\"}"
        name="${name%\"}"
        ;;
      \'*\')
        name="${name#\'}"
        name="${name%\'}"
        ;;
    esac

    if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ || ${#name} -gt 64 ]]; then
      log_err "error: invalid skill name in ${skill_file#$repo_root/}: $name"
      return 1
    fi

    if [[ "$name" != "$entry_name" ]]; then
      log_err "error: skill name '$name' does not match directory '$entry_name'"
      return 1
    fi

    nested_link="$(find "$entry" -type l -print -quit)"
    if [[ -n "$nested_link" ]]; then
      log_err "error: symbolic links are not allowed in Skill contents: ${nested_link#$repo_root/}"
      return 1
    fi

    log_ok "skill ok: ${skill_file#$repo_root/}"

    if command -v npx >/dev/null 2>&1; then
      if NO_COLOR=1 npx --yes --offline skills add "$entry" --list </dev/null >/dev/null 2>&1; then
        log_ok "skill metadata ok: ${skill_file#$repo_root/}"
      else
        log_warn "warning: skipped Skill metadata validation for ${skill_file#$repo_root/}; cached skills CLI unavailable or Skill rejected"
      fi
    else
      log_warn "warning: npx unavailable; skipped Skill metadata validation for ${skill_file#$repo_root/}"
    fi
  done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -print0)
}

while IFS= read -r -d '' json_file; do
  validate_json "$json_file"
  log_ok "json ok: ${json_file#$repo_root/}"
done < <(find "$source_dir" -name '*.json' -type f -print0)

while IFS= read -r -d '' shell_file; do
  bash -n "$shell_file"
  log_ok "shell ok: ${shell_file#$repo_root/}"
done < <(find "$source_dir" "$repo_root/scripts" -name '*.sh' -type f -print0)

validate_skills

log_ok "validation ok"
