#!/usr/bin/env bash
set -uo pipefail

message="${1:-Claude Code needs your attention}"
title="${2:-Claude Code}"

case "$(uname -s)" in
  Darwin)
    if command -v osascript >/dev/null 2>&1; then
      TITLE="$title" MESSAGE="$message" osascript <<'APPLESCRIPT' >/dev/null 2>&1
display notification (system attribute "MESSAGE") with title (system attribute "TITLE")
APPLESCRIPT
      exit 0
    fi
    ;;

  Linux)
    if command -v notify-send >/dev/null 2>&1 && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
      if notify-send "$title" "$message" >/dev/null 2>&1; then
        exit 0
      fi
    fi

    if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
      if tmux display-message "$title: $message" >/dev/null 2>&1; then
        exit 0
      fi
    fi

    printf '\a%s: %s\n' "$title" "$message" >&2
    exit 0
    ;;
esac

exit 0
