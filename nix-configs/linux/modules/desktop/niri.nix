{pkgs, ...}: let
  niriSessionDiagnostic = pkgs.writeShellScript "niri-session-diagnostic" ''
    log() {
      printf '%s\n' "$*" | ${pkgs.systemd}/bin/systemd-cat -t niri-session-diagnostic -p info
    }

    on_exit() {
      status=$?
      trap - EXIT
      log "exited pid=$$ ppid=$PPID session=''${XDG_SESSION_ID:-unset} status=$status"
      exit "$status"
    }

    on_signal() {
      signal=$1
      status=$2
      log "received signal=$signal pid=$$ ppid=$PPID session=''${XDG_SESSION_ID:-unset}"
      exit "$status"
    }

    trap on_exit EXIT
    trap 'on_signal HUP 129' HUP
    trap 'on_signal INT 130' INT
    trap 'on_signal TERM 143' TERM

    log "started pid=$$ ppid=$PPID session=''${XDG_SESSION_ID:-unset} args=$*"
    ${pkgs.niri}/bin/niri-session "$@"
  '';
  niriWithDiagnostics = pkgs.symlinkJoin {
    name = "niri-with-session-diagnostics-${pkgs.niri.version}";
    paths = [pkgs.niri];
    passthru.providedSessions = pkgs.niri.passthru.providedSessions;
    postBuild = ''
      rm "$out/bin/niri-session"
      ln -s ${niriSessionDiagnostic} "$out/bin/niri-session"
    '';
  };
in {
  programs.niri = {
    enable = true;
    package = niriWithDiagnostics;
  };
  programs.dconf.enable = true;
  security.polkit.enable = true;
  hardware.graphics.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
