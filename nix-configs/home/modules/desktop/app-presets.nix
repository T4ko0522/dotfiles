{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep escapeShellArg mapAttrs';

  positiveInt = lib.types.ints.positive;
  percentage = lib.types.addCheck lib.types.number (value: value > 0 && value <= 100);

  appType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.strMatching ".+";
        description = "Name used when reporting progress and errors.";
      };

      command = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.str;
        description = "Command and arguments used when no matching window exists.";
      };

      matcher = {
        appId = lib.mkOption {
          type = lib.types.strMatching ".+";
          description = "Regular expression matched against the Niri app_id.";
        };

        title = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional regular expression matched against the window title.";
        };
      };

      output = lib.mkOption {
        type = lib.types.strMatching ".+";
        description = "Niri output on which to place the window.";
      };

      workspace = lib.mkOption {
        type = positiveInt;
        description = "One-based workspace index on the target output.";
      };

      column = lib.mkOption {
        type = positiveInt;
        description = "One-based column index within the target workspace.";
      };

      columnWidth = lib.mkOption {
        type = percentage;
        description = "Column width as a percentage of the output width.";
      };
    };
  };

  presetType = lib.types.submodule {
    options.apps = lib.mkOption {
      type = lib.types.nonEmptyListOf appType;
      description = "Applications to launch and arrange, in launch order.";
    };
  };

  renderCommand = command: concatMapStringsSep " " escapeShellArg command;

  renderApp = app: let
    titlePattern =
      if app.matcher.title == null
      then ""
      else app.matcher.title;
    hasTitlePattern =
      if app.matcher.title == null
      then "false"
      else "true";
  in ''
      app_name=${escapeShellArg app.name}
      app_id_pattern=${escapeShellArg app.matcher.appId}
      title_pattern=${escapeShellArg titlePattern}
      has_title_pattern=${hasTitlePattern}

      window_id="$(find_window "$app_id_pattern" "$title_pattern" "$has_title_pattern")"
      if [ -z "$window_id" ]; then
        printf 'Starting %s\n' "$app_name"
        (${renderCommand app.command}) 9>&- >/dev/null 2>&1 &

        attempt=0
        while [ "$attempt" -lt 150 ]; do
          ${pkgs.coreutils}/bin/sleep 0.1
          window_id="$(find_window "$app_id_pattern" "$title_pattern" "$has_title_pattern")"
          if [ -n "$window_id" ]; then
            break
          fi
          attempt=$((attempt + 1))
        done
      fi

      if [ -z "$window_id" ]; then
        fail "$app_name: window did not appear within 15 seconds"
      else
    selected_ids="$(
      printf '%s\n' "$selected_ids" \
        | ${lib.getExe pkgs.jq} -c --argjson id "$window_id" '. + [$id]'
    )"

        arrange_window \
          "$app_name" \
          "$window_id" \
          ${escapeShellArg app.output} \
          ${toString app.workspace} \
          ${toString app.column} \
          ${toString app.columnWidth}
      fi
  '';

  mkPresetScript = presetName: preset: let
    presetHash = builtins.hashString "sha256" presetName;
  in {
    executable = true;
    text = lib.concatStringsSep "\n" [
      "#!${pkgs.runtimeShell}"
      "# @vicinae.schemaVersion 1"
      "# @vicinae.title Apps: ${presetName}"
      "# @vicinae.mode compact"
      "# @vicinae.icon 🪟"
      ''# @vicinae.keywords ["apps", "preset", "workspace", "startup"]''
      ""
      (lib.trim ''
            failures=0
            selected_ids='[]'

            runtime_dir="''${XDG_RUNTIME_DIR:-}"
            if [ -z "$runtime_dir" ]; then
              printf 'Error: XDG_RUNTIME_DIR is not set; cannot lock app preset %s\n' ${escapeShellArg presetName} >&2
              exit 1
            fi

            lock_file="$runtime_dir/t4ko-app-preset-${presetHash}.lock"
            if ! exec 9>"$lock_file"; then
              printf 'Error: could not open lock file for app preset %s\n' ${escapeShellArg presetName} >&2
              exit 1
            fi
            if ! ${lib.getExe' pkgs.util-linux "flock"} -n 9; then
              printf 'Error: app preset %s is already running\n' ${escapeShellArg presetName} >&2
              exit 1
            fi

            if ! ${lib.getExe pkgs.niri} msg -j windows >/dev/null 2>&1; then
              printf 'Error: could not query Niri windows\n' >&2
              exit 1
            fi

            original_focus="$(${lib.getExe pkgs.niri} msg -j windows 2>/dev/null \
              | ${lib.getExe pkgs.jq} -r '.[] | select(.is_focused) | .id' \
              | ${pkgs.coreutils}/bin/head -n 1)"

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
                ${pkgs.coreutils}/bin/sleep 0.05
                check_attempt=$((check_attempt + 1))
              done
              return 1
            }

            find_window() {
              app_id_pattern="$1"
              title_pattern="$2"
              has_title_pattern="$3"

              windows_json="$(${lib.getExe pkgs.niri} msg -j windows 2>/dev/null)" || return 1
        printf '%s\n' "$windows_json" \
          | ${lib.getExe pkgs.jq} -r \
            --arg app_id "$app_id_pattern" \
            --arg title "$title_pattern" \
            --argjson has_title "$has_title_pattern" \
            --argjson selected "$selected_ids" '
              [
                .[]
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

              windows_json="$(${lib.getExe pkgs.niri} msg -j windows 2>/dev/null)" || return 1
              workspaces_json="$(${lib.getExe pkgs.niri} msg -j workspaces 2>/dev/null)" || return 1
              target_workspace_id="$(
                printf '%s\n' "$workspaces_json" \
                  | ${lib.getExe pkgs.jq} -r \
                    --arg output "$output" \
                    --argjson workspace "$workspace" \
                    '[.[] | select(.output == $output and .idx == $workspace)] | first | .id // empty'
              )"
              actual_workspace_id="$(
                printf '%s\n' "$windows_json" \
                  | ${lib.getExe pkgs.jq} -r \
                    --argjson id "$window_id" \
                    '[.[] | select(.id == $id)] | first | .workspace_id // empty'
              )"

              [ -n "$target_workspace_id" ] && [ "$actual_workspace_id" = "$target_workspace_id" ]
            }

            window_is_focused() {
              window_id="$1"
              ${lib.getExe pkgs.niri} msg -j windows 2>/dev/null \
                | ${lib.getExe pkgs.jq} -e --argjson id "$window_id" \
                  'any(.[]; .id == $id and .is_focused)' >/dev/null
            }

            column_matches() {
              window_id="$1"
              column="$2"
              ${lib.getExe pkgs.niri} msg -j windows 2>/dev/null \
                | ${lib.getExe pkgs.jq} -e \
                  --argjson id "$window_id" \
                  --argjson column "$column" \
                  'any(.[]; .id == $id and .layout.pos_in_scrolling_layout[0] == $column)' >/dev/null
            }

            width_matches() {
              window_id="$1"
              output="$2"
              requested_width="$3"

              windows_json="$(${lib.getExe pkgs.niri} msg -j windows 2>/dev/null)" || return 1
              outputs_json="$(${lib.getExe pkgs.niri} msg -j outputs 2>/dev/null)" || return 1
              tile_width="$(
                printf '%s\n' "$windows_json" \
                  | ${lib.getExe pkgs.jq} -r \
                    --argjson id "$window_id" \
                    '[.[] | select(.id == $id)] | first | .layout.tile_size[0] // empty'
              )"
              output_width="$(
                printf '%s\n' "$outputs_json" \
                  | ${lib.getExe pkgs.jq} -r \
                    --arg output "$output" \
                    '.[$output].logical.width // empty'
              )"

              [ -n "$tile_width" ] \
                && [ -n "$output_width" ] \
                && ${lib.getExe pkgs.jq} -en \
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

              if ! ${lib.getExe pkgs.niri} msg action move-window-to-monitor --id "$window_id" "$output" >/dev/null; then
                fail "$app_name: could not move window to output $output"
                return
              fi
              if ! ${lib.getExe pkgs.niri} msg action move-window-to-workspace --window-id "$window_id" --focus false "$workspace" >/dev/null; then
                fail "$app_name: could not move window to workspace $workspace on $output"
                return
              fi
              if ! wait_for placement_matches "$window_id" "$output" "$workspace"; then
                fail "$app_name: window is not on workspace $workspace of output $output after moving"
                return
              fi
              if ! ${lib.getExe pkgs.niri} msg action focus-window --id "$window_id" >/dev/null; then
                fail "$app_name: could not focus window $window_id"
                return
              fi
              if ! wait_for window_is_focused "$window_id"; then
                fail "$app_name: window $window_id is not focused after focus action"
                return
              fi
              if ! ${lib.getExe pkgs.niri} msg action move-column-to-index "$column" >/dev/null; then
                fail "$app_name: could not move column to index $column"
                return
              fi
              if ! wait_for column_matches "$window_id" "$column"; then
                fail "$app_name: column did not move to index $column"
                return
              fi
              if ! ${lib.getExe pkgs.niri} msg action set-column-width "$width%" >/dev/null; then
                fail "$app_name: could not set column width to $width%"
                return
              fi
              if ! wait_for width_matches "$window_id" "$output" "$width"; then
                fail "$app_name: column width does not match $width% after resize"
              fi
            }

            ${concatMapStringsSep "\n" renderApp preset.apps}

            if [ -n "$original_focus" ] && ${lib.getExe pkgs.niri} msg -j windows 2>/dev/null \
              | ${lib.getExe pkgs.jq} -e --argjson id "$original_focus" 'any(.[]; .id == $id)' >/dev/null; then
              if ! ${lib.getExe pkgs.niri} msg action focus-window --id "$original_focus" >/dev/null; then
                fail "could not restore the previously focused window"
              fi
            fi

            if [ "$failures" -ne 0 ]; then
              printf 'App preset %s completed with %s error(s)\n' ${escapeShellArg presetName} "$failures" >&2
              exit 1
            fi

            printf 'Applied app preset: %s\n' ${escapeShellArg presetName}
      '')
      ""
    ];
  };

  presetScripts =
    mapAttrs' (
      presetName: preset:
        lib.nameValuePair "vicinae/scripts/apps-${builtins.hashString "sha256" presetName}.sh"
        (mkPresetScript presetName preset)
    )
    config.t4ko.appPresets;
in {
  options.t4ko.appPresets = lib.mkOption {
    type = lib.types.attrsOf presetType;
    default = {};
    description = "Host-specific presets for launching and arranging applications in Niri.";
  };

  config = {
    assertions =
      lib.mapAttrsToList (name: _: {
        assertion = builtins.match "^[A-Za-z0-9][A-Za-z0-9._ -]*$" name != null;
        message = "t4ko.appPresets preset name '${name}' contains unsupported characters.";
      })
      config.t4ko.appPresets;

    xdg.dataFile = presetScripts;
  };
}
