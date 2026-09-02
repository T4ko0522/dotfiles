{
  config,
  lib,
  pkgs,
  ...
}: {
  home.activation = {
    seedCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      codex_cfg="${config.home.homeDirectory}/.codex/config.toml"
      codex_tmpl="${./files/codex-config.toml}"
      mkdir -p "${config.home.homeDirectory}/.codex"
      if [ -L "$codex_cfg" ] || [ ! -e "$codex_cfg" ]; then
        rm -f "$codex_cfg"
        cp "$codex_tmpl" "$codex_cfg"
        chmod u+w "$codex_cfg"
      fi
    '';

    selectCodexPet = lib.hm.dag.entryAfter ["seedCodexConfig"] ''
      codex_cfg="${config.home.homeDirectory}/.codex/config.toml"
      if [ -f "$codex_cfg" ]; then
        codex_cfg_tmp="$codex_cfg.tmp.$$"
        if ${pkgs.gawk}/bin/awk '
          BEGIN {
            in_desktop = 0
            saw_desktop = 0
            found = 0
          }

          /^\[/ {
            if (in_desktop && !found) {
              print "\"selected-avatar-id\" = \"custom:reimu\""
              found = 1
            }
            in_desktop = ($0 ~ /^\[desktop\][[:space:]]*(#.*)?$/)
            if (in_desktop) {
              saw_desktop = 1
            }
          }

          in_desktop && $0 ~ /^[[:space:]]*"selected-avatar-id"[[:space:]]*=/ {
            print "\"selected-avatar-id\" = \"custom:reimu\""
            found = 1
            next
          }

          { print }

          END {
            if (in_desktop && !found) {
              print "\"selected-avatar-id\" = \"custom:reimu\""
            }
            if (!saw_desktop) {
              print ""
              print "[desktop]"
              print "\"selected-avatar-id\" = \"custom:reimu\""
            }
          }
        ' "$codex_cfg" > "$codex_cfg_tmp"; then
          if ! ${pkgs.coreutils}/bin/cmp -s "$codex_cfg_tmp" "$codex_cfg"; then
            ${pkgs.coreutils}/bin/chmod --reference="$codex_cfg" "$codex_cfg_tmp"
            ${pkgs.coreutils}/bin/mv "$codex_cfg_tmp" "$codex_cfg"
          else
            ${pkgs.coreutils}/bin/rm -f "$codex_cfg_tmp"
          fi
        else
          ${pkgs.coreutils}/bin/rm -f "$codex_cfg_tmp"
        fi
      fi
    '';

    migrateCodexSandboxState = lib.hm.dag.entryAfter ["seedCodexConfig"] ''
      codex_dir="${config.home.homeDirectory}/.codex"
      codex_cfg="$codex_dir/config.toml"

      if [ -f "$codex_cfg" ] \
        && ${pkgs.gnugrep}/bin/grep -q '^default_permissions = "personal"$' "$codex_cfg" \
        && ${pkgs.gnugrep}/bin/grep -q '^":root" = "write"$' "$codex_cfg"; then
        ${pkgs.gnused}/bin/sed -i 's/^":root" = "write"$/":root" = "read"/' "$codex_cfg"
      fi

      for state_file in "$codex_dir/.codex-global-state.json" "$codex_dir/.codex-global-state.json.bak"; do
        [ -f "$state_file" ] || continue
        if ${pkgs.jq}/bin/jq -e '
          any(
            ((.["thread-writable-roots"] // {}) | to_entries[]?.value?);
            type == "array" and any(.[]; . == "/")
          )
        ' "$state_file" >/dev/null; then
          state_tmp="$state_file.tmp.$$"
          if ${pkgs.jq}/bin/jq '
            if type == "object" and (.["thread-writable-roots"] | type) == "object" then
              .["thread-writable-roots"] |= with_entries(
                .value |= if type == "array" then map(select(. != "/")) else . end
              )
            else
              .
            end
          ' "$state_file" > "$state_tmp"; then
            ${pkgs.coreutils}/bin/chmod --reference="$state_file" "$state_tmp"
            ${pkgs.coreutils}/bin/mv "$state_tmp" "$state_file"
          else
            ${pkgs.coreutils}/bin/rm -f "$state_tmp"
          fi
        fi
      done
    '';

    normalizeCodexPetPosition = lib.hm.dag.entryAfter ["migrateCodexSandboxState"] ''
      codex_dir="${config.home.homeDirectory}/.codex"

      for state_file in "$codex_dir/.codex-global-state.json" "$codex_dir/.codex-global-state.json.bak"; do
        [ -f "$state_file" ] || continue
        state_tmp="$state_file.tmp.$$"
        if ${pkgs.jq}/bin/jq '
          def bottom_right:
            if (.displayBounds? | type) == "object" then
              .x = (.displayBounds.x + .displayBounds.width - 136)
              | .y = (.displayBounds.y + .displayBounds.height - 145)
              | .placement = "bottom-end"
            else
              .
            end;

          if type == "object" and (. ["electron-avatar-overlay-bounds"] | type) == "object" then
            .["electron-avatar-overlay-bounds"] |= bottom_right
            | if (.["electron-avatar-overlay-bounds"].byDisplayId? | type) == "object" then
                .["electron-avatar-overlay-bounds"].byDisplayId |= with_entries(.value |= bottom_right)
              else
                .
              end
            | if (.["electron-avatar-overlay-bounds"].byResolution? | type) == "object" then
                .["electron-avatar-overlay-bounds"].byResolution |= with_entries(.value |= bottom_right)
              else
                .
              end
          else
            .
          end
        ' "$state_file" > "$state_tmp"; then
          if ! ${pkgs.coreutils}/bin/cmp -s "$state_tmp" "$state_file"; then
            ${pkgs.coreutils}/bin/chmod --reference="$state_file" "$state_tmp"
            ${pkgs.coreutils}/bin/mv "$state_tmp" "$state_file"
          else
            ${pkgs.coreutils}/bin/rm -f "$state_tmp"
          fi
        else
          ${pkgs.coreutils}/bin/rm -f "$state_tmp"
        fi
      done
    '';
  };
}
