# Shared log helpers for scripts/*.sh. Source this file; do not execute it.
#
# Color policy, highest priority first:
#   1. NO_COLOR set to a non-empty value disables color (https://no-color.org/).
#   2. TERM=dumb disables color.
#   3. Color is used only when the destination is a TTY.
#
# stdout and stderr are decided independently so that piping one still colors
# the other.

if [[ -n "${NO_COLOR:-}" || "${TERM:-}" == "dumb" ]]; then
  _log_color_out=false
  _log_color_err=false
else
  [[ -t 1 ]] && _log_color_out=true || _log_color_out=false
  [[ -t 2 ]] && _log_color_err=true || _log_color_err=false
fi

_log_out() {
  local code="$1"
  shift

  if [[ "$_log_color_out" == true ]]; then
    printf '\033[%sm%s\033[0m\n' "$code" "$*"
  else
    printf '%s\n' "$*"
  fi
}

_log_err() {
  local code="$1"
  shift

  if [[ "$_log_color_err" == true ]]; then
    printf '\033[%sm%s\033[0m\n' "$code" "$*" >&2
  else
    printf '%s\n' "$*" >&2
  fi
}

log_ok() { _log_out 32 "$*"; }
log_info() { _log_out 36 "$*"; }
log_dim() { _log_out 2 "$*"; }
log_step() { _log_out '1;34' "$*"; }
log_warn() { _log_err 33 "$*"; }
log_err() { _log_err 31 "$*"; }
