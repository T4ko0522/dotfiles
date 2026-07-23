{
  lib,
  pkgs,
  ...
}: let
  appId = "dev.t4ko.quickshell";
  sessionName = "quick-shell";
  ghosttyConfig = ../../dot_config/nixos/ghostty-quick-shell.conf;
  starshipConfig = ../../dot_config/nixos/starship-quick-shell.toml;

  quickShellSession = pkgs.writeShellApplication {
    name = "quick-shell-session";
    runtimeInputs = with pkgs; [tmux zsh];
    text = ''
      if ! tmux has-session -t "${sessionName}" 2>/dev/null; then
        tmux new-session -d -s "${sessionName}" \
          env QUICK_SHELL=1 STARSHIP_CONFIG=${starshipConfig} zsh -l
      fi

      tmux set-option -t "${sessionName}" status off
      exec tmux attach-session -t "${sessionName}"
    '';
  };

  quickShellWezterm = pkgs.writeShellApplication {
    name = "quick-shell-wezterm";
    runtimeInputs = with pkgs; [coreutils tmux wezterm];
    text = ''
      if [ -z "''${TMUX:-}" ]; then
        echo "quick-shell-wezterm: Quick Shell の中で実行してください" >&2
        exit 1
      fi

      current_session="$(tmux display-message -p '#S')"
      if [ "$current_session" != "${sessionName}" ]; then
        echo "quick-shell-wezterm: Quick Shell の中で実行してください" >&2
        exit 1
      fi

      tmux_socket="''${TMUX%%,*}"
      current_client="$(tmux display-message -p '#{client_tty}')"
      wezterm_pid=""

      if ! wezterm cli spawn -- \
        ${pkgs.tmux}/bin/tmux -S "$tmux_socket" attach-session -t "${sessionName}" >/dev/null 2>&1; then
        wezterm start --always-new-process -- \
          ${pkgs.tmux}/bin/tmux -S "$tmux_socket" attach-session -t "${sessionName}" &
        wezterm_pid=$!
      fi

      for _ in $(seq 1 50); do
        client_count="$(tmux -S "$tmux_socket" list-clients -t "${sessionName}" -F '#{client_tty}' | wc -l)"
        if [ "$client_count" -gt 1 ]; then
          exec tmux detach-client -t "$current_client"
        fi
        if [ -n "$wezterm_pid" ] && ! kill -0 "$wezterm_pid" 2>/dev/null; then
          wait "$wezterm_pid"
          echo "quick-shell-wezterm: WezTerm を起動できませんでした" >&2
          exit 1
        fi
        sleep 0.1
      done

      echo "quick-shell-wezterm: WezTerm の接続を確認できませんでした" >&2
      exit 1
    '';
  };

  quickShellModF = pkgs.writeShellApplication {
    name = "quick-shell-mod-f";
    runtimeInputs = with pkgs; [jq niri tmux];
    text = ''
      if niri msg -j windows \
        | jq -e --arg app_id "${appId}" 'any(.[]; .is_focused and .app_id == $app_id)' >/dev/null; then
        tmux send-keys -t "${sessionName}" \
          "${quickShellWezterm}/bin/quick-shell-wezterm" Enter
      else
        niri msg action maximize-column
      fi
    '';
  };

  quickShell = pkgs.writeShellApplication {
    name = "quick-shell";
    runtimeInputs = with pkgs; [ghostty jq niri];
    text = ''
      app_id="${appId}"
      windows_json="$(niri msg -j windows 2>/dev/null || true)"
      window_id="$(
        printf '%s' "$windows_json" \
          | jq -r --arg app_id "$app_id" '
              [.[] | select(.app_id == $app_id)]
              | sort_by(.focus_timestamp.secs // 0, .focus_timestamp.nanos // 0)
              | last
              | .id // empty
            '
      )"

      if [ -n "$window_id" ]; then
        is_focused="$(
          printf '%s' "$windows_json" \
            | jq -r --argjson id "$window_id" '.[] | select(.id == $id) | .is_focused'
        )"

        if [ "$is_focused" = "true" ]; then
          niri msg action close-window --id "$window_id"
        else
          niri msg action focus-window --id "$window_id"
        fi

        exit 0
      fi

      exec ghostty \
        --config-default-files=false \
        --config-file=${ghosttyConfig} \
        --class="$app_id" \
        -e ${quickShellSession}/bin/quick-shell-session
    '';
  };
in {
  options.t4ko.quickShell = {
    appId = lib.mkOption {
      type = lib.types.str;
      default = appId;
      readOnly = true;
      internal = true;
      description = "Wayland app ID used by the Quick Shell window.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      internal = true;
      description = "Command used by niri to toggle Quick Shell.";
    };

    modFCommand = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      internal = true;
      description = "Command used by niri for the Quick Shell-aware Mod+F binding.";
    };
  };

  config = {
    t4ko.quickShell.command = "${quickShell}/bin/quick-shell";
    t4ko.quickShell.modFCommand = "${quickShellModF}/bin/quick-shell-mod-f";

    home.packages = [
      quickShell
      quickShellWezterm
    ];
  };
}
