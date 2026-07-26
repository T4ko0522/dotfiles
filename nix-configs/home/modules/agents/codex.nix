{
  config,
  lib,
  pkgs,
  ...
}: {
  home = {
    activation = {
      seedCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        codex_cfg="${config.home.homeDirectory}/.codex/config.toml"
        codex_tmpl="${config.home.homeDirectory}/dotfiles/chezmoi/.chezmoitemplates/codex-config.toml"
        mkdir -p "${config.home.homeDirectory}/.codex"
        if [ -L "$codex_cfg" ] || [ ! -e "$codex_cfg" ]; then
          rm -f "$codex_cfg"
          cp "$codex_tmpl" "$codex_cfg"
          chmod u+w "$codex_cfg"
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
    };
  };
}
