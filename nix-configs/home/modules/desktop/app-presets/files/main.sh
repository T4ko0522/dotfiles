    failures=0
    selected_ids='[]'

    runtime_dir="${XDG_RUNTIME_DIR:-}"
    if [ -z "$runtime_dir" ]; then
      printf 'Error: XDG_RUNTIME_DIR is not set; cannot lock app preset %s\n' @preset_name@ >&2
      exit 1
    fi

    lock_file="$runtime_dir/t4ko-app-preset-@preset_hash@.lock"
    if ! exec 9>"$lock_file"; then
      printf 'Error: could not open lock file for app preset %s\n' @preset_name@ >&2
      exit 1
    fi
    if ! @flock@ -n 9; then
      printf 'Error: app preset %s is already running\n' @preset_name@ >&2
      exit 1
    fi

    if ! @niri@ msg -j windows >/dev/null 2>&1; then
      printf 'Error: could not query Niri windows\n' >&2
      exit 1
    fi

    original_focus="$(@niri@ msg -j windows 2>/dev/null \
      | @jq@ -r '.[] | select(.is_focused) | .id' \
      | @head@ -n 1)"

    fail() {
      printf 'Error: %s\n' "$1" >&2
      failures=$((failures + 1))
    }

    wait_for() {
      predicate="$1"
      shift
      check_attempt=0
      while [ "$check_attempt" -lt 20 ]; do
        if "$predicate" "$@"; then
          return 0
        fi
        @sleep@ 0.05
        check_attempt=$((check_attempt + 1))
      done
      return 1
    }

    output_exists() {
      @niri@ msg -j outputs 2>/dev/null \
        | @jq@ -e --arg output "$1" \
          '.[$output].logical != null' >/dev/null
    }

    find_window() {
      app_id_pattern="$1"
      title_pattern="$2"
      has_title_pattern="$3"

      windows_json="$(@niri@ msg -j windows 2>/dev/null)" || return 1
printf '%s\n' "$windows_json" \
  | @jq@ -r \
    --arg app_id "$app_id_pattern" \
    --arg title "$title_pattern" \
    --argjson has_title "$has_title_pattern" \
    --argjson selected "$selected_ids" '
      [
        .[]
        | select(.is_floating == false and .layout.pos_in_scrolling_layout != null)
        | select((.app_id // "") | test($app_id))
        | select(($has_title | not) or ((.title // "") | test($title)))
        | select(.id as $id | ($selected | index($id) | not))
      ]
      | sort_by(.focus_timestamp.secs // 0, .focus_timestamp.nanos // 0)
      | last
      | .id // empty
    '
    }

    placement_matches() {
      window_id="$1"
      output="$2"
      workspace="$3"

      windows_json="$(@niri@ msg -j windows 2>/dev/null)" || return 1
      workspaces_json="$(@niri@ msg -j workspaces 2>/dev/null)" || return 1
      target_workspace_id="$(
        printf '%s\n' "$workspaces_json" \
          | @jq@ -r \
            --arg output "$output" \
            --argjson workspace "$workspace" \
            '[.[] | select(.output == $output and .idx == $workspace)] | first | .id // empty'
      )"
      actual_workspace_id="$(
        printf '%s\n' "$windows_json" \
          | @jq@ -r \
            --argjson id "$window_id" \
            '[.[] | select(.id == $id)] | first | .workspace_id // empty'
      )"

      [ -n "$target_workspace_id" ] && [ "$actual_workspace_id" = "$target_workspace_id" ]
    }

    window_is_focused() {
      window_id="$1"
      @niri@ msg -j windows 2>/dev/null \
        | @jq@ -e --argjson id "$window_id" \
          'any(.[]; .id == $id and .is_focused)' >/dev/null
    }

    column_matches() {
      window_id="$1"
      column="$2"
      @niri@ msg -j windows 2>/dev/null \
        | @jq@ -e \
          --argjson id "$window_id" \
          --argjson column "$column" \
          'any(.[]; .id == $id and .layout.pos_in_scrolling_layout[0] == $column)' >/dev/null
    }

    width_matches() {
      window_id="$1"
      output="$2"
      requested_width="$3"

      windows_json="$(@niri@ msg -j windows 2>/dev/null)" || return 1
      outputs_json="$(@niri@ msg -j outputs 2>/dev/null)" || return 1
      tile_width="$(
        printf '%s\n' "$windows_json" \
          | @jq@ -r \
            --argjson id "$window_id" \
            '[.[] | select(.id == $id)] | first | .layout.tile_size[0] // empty'
      )"
      output_width="$(
        printf '%s\n' "$outputs_json" \
          | @jq@ -r \
            --arg output "$output" \
            '.[$output].logical.width // empty'
      )"

      [ -n "$tile_width" ] \
        && [ -n "$output_width" ] \
        && @jq@ -en \
          --argjson tile "$tile_width" \
          --argjson output "$output_width" \
          --argjson requested "$requested_width" \
          '(($tile * 100 / $output) - $requested) as $difference
           | $difference >= -5 and $difference <= 5' >/dev/null
    }

    arrange_window() {
      app_name="$1"
      window_id="$2"
      output="$3"
      workspace="$4"
      column="$5"
      width="$6"

      if ! @niri@ msg action move-window-to-monitor --id "$window_id" "$output" >/dev/null; then
        fail "$app_name: could not move window to output $output"
        return
      fi
      if ! @niri@ msg action move-window-to-workspace --window-id "$window_id" --focus false "$workspace" >/dev/null; then
        fail "$app_name: could not move window to workspace $workspace on $output"
        return
      fi
      if ! wait_for placement_matches "$window_id" "$output" "$workspace"; then
        fail "$app_name: window is not on workspace $workspace of output $output after moving"
        return
      fi
      if ! @niri@ msg action focus-window --id "$window_id" >/dev/null; then
        fail "$app_name: could not focus window $window_id"
        return
      fi
      if ! wait_for window_is_focused "$window_id"; then
        fail "$app_name: window $window_id is not focused after focus action"
        return
      fi
      if ! @niri@ msg action move-column-to-index "$column" >/dev/null; then
        fail "$app_name: could not move column to index $column"
        return
      fi
      if ! wait_for column_matches "$window_id" "$column"; then
        fail "$app_name: column did not move to index $column"
        return
      fi
      if ! @niri@ msg action set-column-width "$width%" >/dev/null; then
        fail "$app_name: could not set column width to $width%"
        return
      fi
      if ! wait_for width_matches "$window_id" "$output" "$width"; then
        fail "$app_name: column width does not match $width% after resize"
      fi
    }

    @apps@

    if [ -n "$original_focus" ] && @niri@ msg -j windows 2>/dev/null \
      | @jq@ -e --argjson id "$original_focus" 'any(.[]; .id == $id)' >/dev/null; then
      if ! @niri@ msg action focus-window --id "$original_focus" >/dev/null; then
        fail "could not restore the previously focused window"
      fi
    fi

    if [ "$failures" -ne 0 ]; then
      printf 'App preset %s completed with %s error(s)\n' @preset_name@ "$failures" >&2
      exit 1
    fi

    printf 'Applied app preset: %s\n' @preset_name@
