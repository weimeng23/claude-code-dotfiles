#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/log.sh"
skills_dir="$repo_root/claude-user/skills"
manifest="$repo_root/claude-user/skills-sources.json"

usage() {
  log_warn "usage:"
  log_warn "  import-skill.sh [--full-depth] <owner/repo-or-url> <skill-name> [skill-name ...]"
  log_warn "      Import new skills and record their source in skills-sources.json."
  log_warn ""
  log_warn "  import-skill.sh --update <skill-name> [skill-name ...]"
  log_warn "      Re-import existing skills from their recorded source (latest upstream)."
  log_warn ""
  log_warn "  import-skill.sh --update --all"
  log_warn "      Re-import every skill listed in skills-sources.json."
}

# Manifest access is centralized here so the JSON schema lives in one place.
require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    log_err "error: python3 is required to read/write $manifest"
    exit 1
  fi
}

# Exit 3: unreadable/invalid JSON (python already printed).
# Exit 4: missing file or missing skill entry.
manifest_get() {
  local skill="$1"
  python3 - "$manifest" "$skill" <<'PY'
import json, os, sys

path, skill = sys.argv[1], sys.argv[2]
if not os.path.exists(path):
    sys.exit(4)
try:
    with open(path) as fh:
        data = json.load(fh)
except (OSError, json.JSONDecodeError) as exc:
    sys.stderr.write("error: cannot parse %s: %s\n" % (path, exc))
    sys.exit(3)
if not isinstance(data, dict):
    sys.stderr.write("error: %s must be a JSON object\n" % path)
    sys.exit(3)
entry = data.get(skill)
if not isinstance(entry, dict) or "package" not in entry:
    sys.exit(4)
print("%s\t%s" % (entry["package"], "true" if entry.get("fullDepth") else "false"))
PY
}

manifest_names() {
  python3 - "$manifest" <<'PY'
import json, os, sys

path = sys.argv[1]
if not os.path.exists(path):
    sys.exit(0)
try:
    with open(path) as fh:
        data = json.load(fh)
except (OSError, json.JSONDecodeError) as exc:
    sys.stderr.write("error: cannot parse %s: %s\n" % (path, exc))
    sys.exit(3)
if not isinstance(data, dict):
    sys.stderr.write("error: %s must be a JSON object\n" % path)
    sys.exit(3)
for name in sorted(data):
    print(name)
PY
}

manifest_upsert() {
  local skill="$1" package="$2" full_depth="$3"
  python3 - "$manifest" "$skill" "$package" "$full_depth" <<'PY'
import json, os, sys, tempfile

path, skill, package, full_depth = sys.argv[1:5]
data = {}
if os.path.exists(path):
    try:
        with open(path) as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        sys.stderr.write("error: cannot parse %s: %s\n" % (path, exc))
        sys.exit(3)
    if not isinstance(data, dict):
        sys.stderr.write("error: %s must be a JSON object\n" % path)
        sys.exit(3)

entry = dict(data[skill]) if isinstance(data.get(skill), dict) else {}
entry["package"] = package
if full_depth == "true":
    entry["fullDepth"] = True
else:
    entry.pop("fullDepth", None)
data[skill] = entry

directory = os.path.dirname(path) or "."
fd, tmp = tempfile.mkstemp(prefix=".skills-sources.", suffix=".tmp", dir=directory)
try:
    with os.fdopen(fd, "w") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)
        fh.write("\n")
    os.replace(tmp, path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
PY
}

validate_name() {
  local skill_name="$1"
  if [[ ! "$skill_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ || ${#skill_name} -gt 64 ]]; then
    log_err "error: invalid skill name: $skill_name"
    exit 2
  fi
}

require_npx() {
  if ! command -v npx >/dev/null 2>&1; then
    log_err "error: npx is required to import skills"
    exit 1
  fi
}

# Download one package into a fresh work subdir and copy the requested skills
# into the repository. Registers each target before copying so a failed copy
# is still removed by the cleanup trap.
fetch_into_repo() {
  local package="$1" full_depth="$2"
  shift 2
  local names=("$@")
  local sub depth_flag=() name source_dir

  sub="$(mktemp -d "$work_dir/fetch.XXXXXX")"
  if [[ "$full_depth" == "true" ]]; then
    depth_flag=(--full-depth)
  fi

  (
    cd "$sub"
    npx --yes skills add "$package" \
      --skill "${names[@]}" \
      --agent claude-code \
      --copy \
      ${depth_flag[@]+"${depth_flag[@]}"} \
      -y
  )

  for name in "${names[@]}"; do
    source_dir="$sub/.agents/skills/$name"
    if [[ ! -d "$source_dir" ]]; then
      source_dir="$sub/.claude/skills/$name"
    fi
    if [[ ! -d "$source_dir" || ! -f "$source_dir/SKILL.md" ]]; then
      log_err "error: imported skill not found: $name"
      return 1
    fi
    created_dirs+=("$skills_dir/$name")
    cp -R "$source_dir" "$skills_dir/$name"
  done
}

# --- argument parsing -------------------------------------------------------

mode="import"
full_depth="false"
update_all="false"

case "${1:-}" in
  --update-all)
    log_err "error: use --update --all"
    exit 2
    ;;
  --update)
    mode="update"
    shift
    ;;
esac

declare -a skill_names=()
package=""

if [[ "$mode" == "import" ]]; then
  if [[ "${1:-}" == "--full-depth" ]]; then
    full_depth="true"
    shift
  fi
  package="${1:-}"
  skill_names=("${@:2}")
  if [[ -z "$package" || ${#skill_names[@]} -lt 1 ]]; then
    usage
    exit 2
  fi
elif [[ "$mode" == "update" ]]; then
  for arg in "$@"; do
    if [[ "$arg" == "--all" ]]; then
      update_all="true"
    else
      skill_names+=("$arg")
    fi
  done

  if [[ "$update_all" == "true" && ${#skill_names[@]} -gt 0 ]]; then
    log_err "error: --all cannot be combined with skill names"
    exit 2
  fi

  if [[ "$update_all" != "true" && ${#skill_names[@]} -lt 1 ]]; then
    usage
    exit 2
  fi
fi

require_npx
require_python

if [[ "$update_all" == "true" ]]; then
  if ! names_raw="$(manifest_names)"; then
    exit 1
  fi
  while IFS= read -r name; do
    [[ -n "$name" ]] && skill_names+=("$name")
  done <<< "$names_raw"
  if [[ ${#skill_names[@]} -lt 1 ]]; then
    log_err "error: no skills recorded in ${manifest#$repo_root/}"
    exit 1
  fi
fi

# --- validation & source resolution ----------------------------------------

seen_names=" "
for skill_name in "${skill_names[@]}"; do
  validate_name "$skill_name"
  if [[ "$seen_names" == *" $skill_name "* ]]; then
    log_err "error: duplicate skill name: $skill_name"
    exit 2
  fi
  seen_names+="$skill_name "
done

if [[ "$mode" == "import" ]]; then
  for skill_name in "${skill_names[@]}"; do
    target_dir="$skills_dir/$skill_name"
    if [[ -e "$target_dir" || -L "$target_dir" ]]; then
      log_err "error: skill already exists: ${target_dir#$repo_root/}"
      log_warn "hint: use 'import-skill.sh --update $skill_name' to refresh it"
      exit 1
    fi
  done
fi

# --- workspace & rollback ---------------------------------------------------

mkdir -p "$repo_root/tmp" "$skills_dir"
work_dir="$(mktemp -d "$repo_root/tmp/skill-import.XXXXXX")"
timestamp="$(date +%Y%m%d-%H%M%S)"
declare -a created_dirs=()
declare -a backup_skills=()
declare -a backup_dirs=()
completed=false

cleanup() {
  local status=$?
  local index keep

  if [[ "$completed" != true ]]; then
    if ((${#created_dirs[@]})); then
      for index in "${!created_dirs[@]}"; do
        rm -rf "${created_dirs[$index]}"
      done
    fi
    if ((${#backup_skills[@]})); then
      for index in "${!backup_skills[@]}"; do
        rm -rf "$skills_dir/${backup_skills[$index]}"
        mv "${backup_dirs[$index]}" "$skills_dir/${backup_skills[$index]}"
      done
    fi
  elif ((${#backup_skills[@]})); then
    keep="$repo_root/backups/skill-update-$timestamp"
    mkdir -p "$keep"
    for index in "${!backup_skills[@]}"; do
      mv "${backup_dirs[$index]}" "$keep/${backup_skills[$index]}"
      log_info "backup: claude-user/skills/${backup_skills[$index]} -> ${keep#$repo_root/}/${backup_skills[$index]}"
    done
  fi

  rm -rf "$work_dir"
  return "$status"
}

trap cleanup EXIT

# --- import mode ------------------------------------------------------------

if [[ "$mode" == "import" ]]; then
  fetch_into_repo "$package" "$full_depth" "${skill_names[@]}"

  if ! "$repo_root/scripts/validate.sh"; then
    log_err "error: imported skills failed validation and were removed"
    exit 1
  fi

  for skill_name in "${skill_names[@]}"; do
    manifest_upsert "$skill_name" "$package" "$full_depth"
  done

  completed=true
  for skill_name in "${skill_names[@]}"; do
    log_ok "imported: $package@$skill_name -> claude-user/skills/$skill_name"
  done
  log_ok "recorded: ${manifest#$repo_root/}"
  log_info "next: review the imported files, then run scripts/install-skills.sh all"
  exit 0
fi

# --- update mode ------------------------------------------------------------

declare -a skill_packages=()
declare -a skill_depths=()

for skill_name in "${skill_names[@]}"; do
  if source_line="$(manifest_get "$skill_name")"; then
    skill_packages+=("${source_line%%$'\t'*}")
    skill_depths+=("${source_line##*$'\t'}")
  else
    status=$?
    if [[ "$status" -eq 4 ]]; then
      log_err "error: no recorded source for skill: $skill_name"
      log_warn "hint: import it first with 'import-skill.sh <owner/repo> $skill_name'"
    fi
    exit 1
  fi
done

for index in "${!skill_names[@]}"; do
  skill_name="${skill_names[$index]}"
  target_dir="$skills_dir/$skill_name"
  if [[ -d "$target_dir" ]]; then
    backup_dir="$work_dir/backup-$skill_name"
    mv "$target_dir" "$backup_dir"
    backup_skills+=("$skill_name")
    backup_dirs+=("$backup_dir")
  fi
done

for index in "${!skill_names[@]}"; do
  already="false"
  if ((index > 0)); then
    for ((prior = 0; prior < index; prior++)); do
      if [[ "${skill_packages[$prior]}" == "${skill_packages[$index]}" && "${skill_depths[$prior]}" == "${skill_depths[$index]}" ]]; then
        already="true"
        break
      fi
    done
  fi
  [[ "$already" == "true" ]] && continue

  group_names=()
  for ((other = 0; other < ${#skill_names[@]}; other++)); do
    if [[ "${skill_packages[$other]}" == "${skill_packages[$index]}" && "${skill_depths[$other]}" == "${skill_depths[$index]}" ]]; then
      group_names+=("${skill_names[$other]}")
    fi
  done
  fetch_into_repo "${skill_packages[$index]}" "${skill_depths[$index]}" "${group_names[@]}"
done

if ! "$repo_root/scripts/validate.sh"; then
  log_err "error: updated skills failed validation and were rolled back"
  exit 1
fi

completed=true

# Report per-skill diffs against the pre-update backups.
if ((${#backup_skills[@]})); then
  for index in "${!backup_skills[@]}"; do
    skill_name="${backup_skills[$index]}"
    log_step "=== diff: $skill_name ==="
    if diff -ru "${backup_dirs[$index]}" "$skills_dir/$skill_name" >/dev/null 2>&1; then
      log_dim "unchanged: $skill_name"
    else
      diff -ru "${backup_dirs[$index]}" "$skills_dir/$skill_name" || true
      log_ok "updated: $skill_name"
    fi
  done
fi

log_info "next: review the changes above, then run scripts/install-skills.sh all"
