#!/usr/bin/env bash

usage() {
  printf '%s\n' "usage: niri-popupctl {close-on-focus-loss APP_ID_PATTERN|open-primary-selection URI_PREFIX|open-uri URI}" >&2
  exit 64
}

declare -A popup_window_ids=()
armed=false

close_popup_windows() {
  local id

  for id in "${!popup_window_ids[@]}"; do
    niri msg action close-window --id "$id" || true
  done

  popup_window_ids=()
  armed=false
}

sync_popup_windows() {
  local windows="$1"
  local id
  local focused

  popup_window_ids=()
  armed=false
  while IFS=$'\t' read -r id focused; do
    popup_window_ids["$id"]=1
    if [ "$focused" = true ]; then
      armed=true
    fi
  done < <(jq -r --arg pattern "$app_id_pattern" '.[] | select((.app_id // "") | test($pattern; "i")) | [.id, .is_focused] | @tsv' <<<"$windows")

  return 0
}

handle_window_opened_or_changed() {
  local event="$1"
  local window
  local id

  window="$(jq -cer '.WindowOpenedOrChanged.window? // empty' <<<"$event")" || return 0
  if ! jq -e --arg pattern "$app_id_pattern" '(.app_id // "") | test($pattern; "i")' <<<"$window" >/dev/null; then
    if [ "$armed" = true ] && jq -e '.is_focused' <<<"$window" >/dev/null; then
      close_popup_windows
    fi
    return
  fi
  id="$(jq -er '.id' <<<"$window")" || return 0

  popup_window_ids["$id"]=1
  if jq -e '.is_focused' <<<"$window" >/dev/null; then
    armed=true
  fi
}

handle_window_closed() {
  local event="$1"
  local id

  id="$(jq -er '.WindowClosed.id? // empty' <<<"$event")" || return 0
  unset 'popup_window_ids[$id]'
  if [ "${#popup_window_ids[@]}" -eq 0 ]; then
    armed=false
  fi

  return 0
}

handle_window_focus_changed() {
  local event="$1"
  local id

  if id="$(jq -er '.WindowFocusChanged.id? // empty' <<<"$event")" && [[ -v popup_window_ids[$id] ]]; then
    armed=true
    return
  fi

  if [ "$armed" = true ]; then
    close_popup_windows
  fi

  return 0
}

handle_event() {
  local event="$1"
  local windows

  if windows="$(jq -cer '.WindowsChanged.windows? // empty' <<<"$event")"; then
    sync_popup_windows "$windows"
    return
  fi

  if jq -e 'has("WindowOpenedOrChanged")' <<<"$event" >/dev/null; then
    handle_window_opened_or_changed "$event"
  elif jq -e 'has("WindowClosed")' <<<"$event" >/dev/null; then
    handle_window_closed "$event"
  elif jq -e 'has("WindowFocusChanged")' <<<"$event" >/dev/null; then
    handle_window_focus_changed "$event"
  fi

  return 0
}

close_on_focus_loss() {
  app_id_pattern="$1"
  popup_window_ids=()
  armed=false

  local event
  while IFS= read -r event; do
    handle_event "$event"
  done < <(niri msg --json event-stream)

  exit 1
}

open_primary_selection() {
  local uri_prefix="$1"
  local selection
  local selection_uri

  selection="$(wl-paste --primary --no-newline)"
  [ -n "$selection" ] || return

  selection_uri="$(printf '%s' "$selection" | jq -sRr @uri)"
  xdg-open "${uri_prefix}${selection_uri}"
}

open_uri() {
  xdg-open "$1"
}

main() {
  case "${1:-}" in
    close-on-focus-loss)
      [ "$#" -eq 2 ] || usage
      close_on_focus_loss "$2"
      ;;
    open-primary-selection)
      [ "$#" -eq 2 ] || usage
      open_primary_selection "$2"
      ;;
    open-uri)
      [ "$#" -eq 2 ] || usage
      open_uri "$2"
      ;;
    *) usage ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
