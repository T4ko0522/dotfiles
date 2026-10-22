app_name=@app_name@
app_id_pattern=@app_id_pattern@
title_pattern=@title_pattern@
has_title_pattern=@has_title_pattern@

app_output=@app_output@
launch_failed=false
window_id=""

if ! output_exists "$app_output"; then
  fail "$app_name: output $app_output is not available"
else
  window_id="$(find_window "$app_id_pattern" "$title_pattern" "$has_title_pattern")"
  if [ -z "$window_id" ]; then
    unit_name="@unit_prefix@-$(@date@ +%s%N).service"
    command_path="$(command -v -- @command@)"
    if [ -z "$command_path" ] || ! command_path="$(@realpath@ -e -- "$command_path")"; then
      fail "$app_name: command not found: "@command@
      launch_failed=true
    else
      printf 'Starting %s\n' "$app_name"
      if ! @systemd_run@ --user --collect --service-type=exec \
        --property=ExitType=cgroup \
        --property=PartOf=graphical-session.target \
        --unit="$unit_name" \
        --setenv="PATH=$PATH" \
        --expand-environment=no \
        -- "$command_path" @arguments@ 9>&-; then
        fail "$app_name: could not start application; inspect journalctl --user -u $unit_name"
        launch_failed=true
      fi
    fi

    if [ "$launch_failed" = false ]; then
      attempt=0
      while [ "$attempt" -lt @startup_attempts@ ]; do
        @sleep@ 0.1
        window_id="$(find_window "$app_id_pattern" "$title_pattern" "$has_title_pattern")"
        if [ -n "$window_id" ]; then
          break
        fi
        if @systemctl@ --user is-failed --quiet "$unit_name"; then
          fail "$app_name: application failed; inspect journalctl --user -u $unit_name"
          launch_failed=true
          break
        fi
        attempt=$((attempt + 1))
      done
    fi
  fi

  if [ "$launch_failed" = false ]; then
    if [ -z "$window_id" ]; then
      fail "$app_name: tiled window did not appear within @startup_timeout@ seconds; inspect journalctl --user -u $unit_name"
    else
      selected_ids="$(
        printf '%s\n' "$selected_ids" \
          | @jq@ -c --argjson id "$window_id" '. + [$id]'
      )"

      arrange_window \
        "$app_name" \
        "$window_id" \
        "$app_output" \
        @workspace@ \
        @column@ \
        @column_width@
    fi
  fi
fi
