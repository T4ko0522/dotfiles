{
  config,
  lib,
  pkgs,
  ...
}: let
  c = import ../lib/catppuccin-mocha.nix;
  niriCfg = config.t4ko.niri;
  wallpaperCfg = config.t4ko.wallpaper;
  mainMonitors = lib.filterAttrs (_: monitor: monitor.focusAtStartup) niriCfg.monitors;
  mainMonitor = lib.head (lib.attrNames mainMonitors);
  secondaryMonitors = lib.attrNames (lib.filterAttrs (name: _: name != mainMonitor) niriCfg.monitors);
  nixosLogo = pkgs.fetchurl {
    url = "https://brand.nixos.org/logos/nixos-logo-default-gradient-black-regular-vertical-recommended.svg";
    hash = "sha256-gm9EU3wZVpW4yALwdSjVppDnMnpX8cbdsXS/Yzhpx74=";
  };
  background = pkgs.runCommand "nixos-lockscreen.svg" {} ''
    {
      printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">'
      printf '%s\n' '  <rect width="1920" height="1080" fill="#eff1f5"/>'
      sed 's#<svg #<svg x="750" y="235" width="420" height="420" preserveAspectRatio="xMidYMid meet" #' "${nixosLogo}"
      printf '%s\n' '  <text x="960" y="765" fill="${c.crust}" font-family="sans-serif" font-size="58" font-weight="600" text-anchor="middle">I use NixOS btw.</text>'
      printf '%s\n' '</svg>'
    } > "$out"
  '';
  swaylock = pkgs.swaylock.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace password.c \
          --replace-fail "state->eventloop, 1500, set_input_idle, state" \
          "state->eventloop, 10000, set_input_idle, state"
      '';
  });
  lockscreen = pkgs.writeShellApplication {
    name = "lockscreen";
    runtimeInputs = [pkgs.niri swaylock];
    text = ''
      restore_monitors() {
        ${lib.concatMapStringsSep "\n" (monitor: "niri msg output ${lib.escapeShellArg monitor} on || true") secondaryMonitors}
      }

      trap restore_monitors EXIT HUP INT TERM

      ${lib.concatMapStringsSep "\n" (monitor: "niri msg output ${lib.escapeShellArg monitor} off || true") secondaryMonitors}
      if swaylock \
        --color eff1f5 \
        --image ${lib.escapeShellArg "${mainMonitor}:${background}"} \
        --scaling fill \
        --indicator-radius 110 \
        --indicator-thickness 10 \
        --inside-color ${lib.removePrefix "#" c.mantle} \
        --ring-color ${lib.removePrefix "#" c.lavender} \
        --line-color 00000000 \
        --text-color ${lib.removePrefix "#" c.fg} \
        --key-hl-color ${lib.removePrefix "#" c.blue} \
        --bs-hl-color ${lib.removePrefix "#" c.red}; then
        lock_status=0
      else
        lock_status=$?
      fi

      restore_monitors
      trap - EXIT HUP INT TERM

      if [ "$lock_status" -eq 0 ]; then
        ${lib.getExe wallpaperCfg.presetCommand} ${lib.escapeShellArg wallpaperCfg.activePreset}
      fi

      exit "$lock_status"
    '';
  };
in {
  options.t4ko.lockscreen.command = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "Command that locks the session and powers off secondary outputs.";
  };

  config = {
    assertions = [
      {
        assertion = lib.length (lib.attrNames mainMonitors) == 1;
        message = "Exactly one t4ko.niri.monitors entry must set focusAtStartup for the lock screen.";
      }
    ];

    t4ko.lockscreen.command = lockscreen;
  };
}
