#!/usr/bin/env bash
# Claude Code Notification Hook
# Reads JSON from stdin, shows toast notification + plays sound.
# Windows: snoretoast + ffplay, Linux: notify-send + mpv/paplay

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUND_FILE="${HOME}/.claude/sounds.mp3"
APP_LOGO="${SCRIPT_DIR}/claude-icon.svg"

json="$(cat)"
[[ -z "$json" ]] && exit 0

type="$(echo "$json" | jq -r '.notification_type // empty' 2>/dev/null)" || exit 1
[[ -z "$type" ]] && exit 0

case "$type" in
  permission_prompt)
    title="Claude Code - Permission Required"
    message="Claude is waiting for your approval."
    ;;
  idle_prompt)
    title="Claude Code - Task Complete"
    message="Claude has finished and is waiting for input."
    ;;
  *) exit 0 ;;
esac

# --- Sound ---
play_sound() {
  [[ ! -f "$SOUND_FILE" ]] && return
  if command -v ffplay &>/dev/null; then
    ffplay -nodisp -autoexit -loglevel quiet "$SOUND_FILE" &
  elif command -v mpv &>/dev/null; then
    mpv --no-video --really-quiet "$SOUND_FILE" &
  elif command -v paplay &>/dev/null; then
    paplay "$SOUND_FILE" &
  fi
}

# --- Notification ---
notify() {
  if command -v snoretoast &>/dev/null || command -v snoretoast.exe &>/dev/null; then
    local args=(-t "$title" -m "$message" -silent)
    [[ -f "$APP_LOGO" ]] && args+=(-p "$APP_LOGO")
    snoretoast "${args[@]}" &
  elif command -v notify-send &>/dev/null; then
    notify-send "$title" "$message" &
  fi
}

play_sound
notify
wait
