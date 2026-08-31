#!/usr/bin/env bash

set -euo pipefail

: "${ECO_MODE_STATE_DIR:?ECO_MODE_STATE_DIR is required}"
: "${ECO_MODE_TARGET_UNITS:?ECO_MODE_TARGET_UNITS is required}"
: "${ECO_MODE_WALLPAPER_UNIT:?ECO_MODE_WALLPAPER_UNIT is required}"
: "${ECO_MODE_WALLPAPER_RESTORE:?ECO_MODE_WALLPAPER_RESTORE is required}"
: "${ECO_MODE_WALLPAPER_RESTORE_UNIT:?ECO_MODE_WALLPAPER_RESTORE_UNIT is required}"
: "${ECO_MODE_WAYBAR_UNIT:?ECO_MODE_WAYBAR_UNIT is required}"
: "${ECO_MODE_POWER_PROFILES_COMMAND:?ECO_MODE_POWER_PROFILES_COMMAND is required}"
: "${ECO_MODE_LIGHTING_COMMAND:=}"

enabled_file="$ECO_MODE_STATE_DIR/enabled"
restore_units_file="$ECO_MODE_STATE_DIR/restore-units"
power_profile_file="$ECO_MODE_STATE_DIR/power-profile"
lock_file="$ECO_MODE_STATE_DIR/lock"

target_units=()
while IFS= read -r unit; do
  if [[ -n "$unit" ]]; then
    target_units+=("$unit")
  fi
done <<<"$ECO_MODE_TARGET_UNITS"

lock_state() {
  mkdir -p "$ECO_MODE_STATE_DIR"
  exec 9>"$lock_file"
  flock 9
}

reload_waybar() {
  systemctl --user try-restart "$ECO_MODE_WAYBAR_UNIT" >/dev/null 2>&1 || true
}

stop_targets() {
  systemctl --user stop "$ECO_MODE_WALLPAPER_RESTORE_UNIT" >/dev/null 2>&1 || true

  local unit
  for unit in "${target_units[@]}"; do
    systemctl --user stop "$unit" >/dev/null 2>&1 || true
  done
}

record_active_units() {
  local restore_units_tmp="$restore_units_file.tmp.$$"
  local unit

  : >"$restore_units_tmp"
  for unit in "${target_units[@]}"; do
    if systemctl --user is-active --quiet "$unit"; then
      printf '%s\n' "$unit" >>"$restore_units_tmp"
    fi
  done
  mv -f "$restore_units_tmp" "$restore_units_file"
}

record_power_profile() {
  local power_profile_tmp="$power_profile_file.tmp.$$"
  local power_profile

  if power_profile="$("$ECO_MODE_POWER_PROFILES_COMMAND" get 2>/dev/null)" && [[ -n "$power_profile" ]]; then
    printf '%s\n' "$power_profile" >"$power_profile_tmp"
    mv -f "$power_profile_tmp" "$power_profile_file"
  else
    rm -f "$power_profile_tmp"
  fi
}

enable_power_saver() {
  "$ECO_MODE_POWER_PROFILES_COMMAND" set power-saver >/dev/null 2>&1 || true
}

set_lighting() {
  local state=$1

  if [[ -n "$ECO_MODE_LIGHTING_COMMAND" ]]; then
    "$ECO_MODE_LIGHTING_COMMAND" "$state" >/dev/null 2>&1 || true
  fi
}

enable_mode() {
  lock_state

  if [[ ! -e "$enabled_file" ]]; then
    record_active_units
    record_power_profile
    local enabled_tmp="$enabled_file.tmp.$$"
    : >"$enabled_tmp"
    mv -f "$enabled_tmp" "$enabled_file"
  fi

  stop_targets
  enable_power_saver
  set_lighting off
  reload_waybar
}

restore_unit() {
  local unit=$1

  if [[ "$unit" == "$ECO_MODE_WALLPAPER_UNIT" ]]; then
    systemctl --user reset-failed "$ECO_MODE_WALLPAPER_RESTORE_UNIT" >/dev/null 2>&1 || true
    systemd-run \
      --user \
      --collect \
      --quiet \
      --unit="${ECO_MODE_WALLPAPER_RESTORE_UNIT%.service}" \
      "$ECO_MODE_WALLPAPER_RESTORE"
  else
    systemctl --user start "$unit"
  fi
}

disable_mode() {
  local power_profile
  local restore_status=0

  lock_state

  rm -f "$enabled_file"

  if [[ -f "$restore_units_file" ]]; then
    while IFS= read -r unit; do
      if [[ -n "$unit" ]]; then
        if ! restore_unit "$unit"; then
          printf 'failed to restore eco mode target: %s\n' "$unit" >&2
          restore_status=1
        fi
      fi
    done <"$restore_units_file"
    rm -f "$restore_units_file"
  fi

  if [[ -f "$power_profile_file" ]]; then
    power_profile="$(<"$power_profile_file")"
    if [[ -n "$power_profile" ]]; then
      "$ECO_MODE_POWER_PROFILES_COMMAND" set "$power_profile" >/dev/null 2>&1 || true
    fi
    rm -f "$power_profile_file"
  fi

  set_lighting on
  reload_waybar
  return "$restore_status"
}

apply_mode() {
  lock_state

  if [[ -e "$enabled_file" ]]; then
    stop_targets
    enable_power_saver
    set_lighting off
  fi
}

print_status() {
  if [[ -e "$enabled_file" ]]; then
    printf '%s\n' '{"text":"","class":"enabled","tooltip":"Eco mode: ON\\nPower saver is active; Wallpaper Engine, WiVRn, and Cava are stopped"}'
  else
    printf '%s\n' '{"text":"","class":"disabled","tooltip":"Eco mode: OFF\\nClick to enable power saver and stop Wallpaper Engine, WiVRn, and Cava"}'
  fi
}

case "${1:-status}" in
  apply)
    apply_mode
    ;;
  disable)
    disable_mode
    ;;
  enable)
    enable_mode
    ;;
  status)
    print_status
    ;;
  toggle)
    if [[ -e "$enabled_file" ]]; then
      disable_mode
    else
      enable_mode
    fi
    ;;
  *)
    printf 'usage: eco-mode {status|toggle|enable|disable|apply}\n' >&2
    exit 2
    ;;
esac
