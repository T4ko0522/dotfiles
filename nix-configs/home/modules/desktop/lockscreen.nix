{
  config,
  lib,
  pkgs,
  ...
}: let
  c = import ../../../lib/theme.nix;
  niriCfg = config.t4ko.niri;
  wallpaperCfg = config.t4ko.wallpaper;
  restoreWallpaperCommand = lib.getExe wallpaperCfg.restoreCommand;
  mainMonitors = lib.filterAttrs (_: monitor: monitor.focusAtStartup) niriCfg.monitors;
  mainMonitor = lib.head (lib.attrNames mainMonitors);
  secondaryMonitors = lib.attrNames (lib.filterAttrs (name: _: name != mainMonitor) niriCfg.monitors);
  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-nineish.png";
    hash = "sha256-EMSD1XQLaqHs0NbLY0lS1oZ4rKznO+h9XOGDS121m9c=";
  };
  nixosLogo = pkgs.fetchurl {
    url = "https://brand.nixos.org/logos/nixos-logo-default-gradient-black-regular-vertical-recommended.svg";
    hash = "sha256-gm9EU3wZVpW4yALwdSjVppDnMnpX8cbdsXS/Yzhpx74=";
  };
  background =
    pkgs.runCommand "nixos-lockscreen.png"
    {
      nativeBuildInputs = [pkgs.imagemagick];
    }
    ''
      magick "${wallpaper}" \
        -resize '1920x1080^' \
        -gravity center \
        -extent 1920x1080 \
        \( -background none "${nixosLogo}" -resize 420x420 \) \
        -gravity north \
        -geometry +0+235 \
        -composite \
        "$out"
    '';
  lockscreen = pkgs.writeShellApplication {
    name = "lockscreen";
    runtimeInputs = [
      pkgs.niri
      config.programs.hyprlock.package
    ];
    text = ''
      restore_monitors() {
        ${lib.concatMapStringsSep "\n" (
          monitor: "niri msg output ${lib.escapeShellArg monitor} on || true"
        )
        secondaryMonitors}
      }

      trap restore_monitors EXIT HUP INT TERM

      ${lib.concatMapStringsSep "\n" (
          monitor: "niri msg output ${lib.escapeShellArg monitor} off || true"
        )
        secondaryMonitors}
      if hyprlock --config ${config.xdg.configFile."hypr/hyprlock.conf".source}; then
        lock_status=0
      else
        lock_status=$?
      fi

      restore_monitors
      trap - EXIT HUP INT TERM

      if [ "$lock_status" -eq 0 ]; then
        ${restoreWallpaperCommand}
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

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
        };
        background = [
          {
            monitor = "";
            color = "rgb(eff1f5)";
            zindex = -2;
          }
          {
            monitor = mainMonitor;
            path = "${background}";
            blur_passes = 0;
          }
        ];
        input-field = [
          {
            monitor = mainMonitor;
            size = "220, 220";
            position = "0, 0";
            halign = "center";
            valign = "center";
            rounding = -1;
            outline_thickness = 10;
            inner_color = "rgb(${lib.removePrefix "#" c.mantle})";
            outer_color = "rgb(${lib.removePrefix "#" c.lavender})";
            font_color = "rgb(${lib.removePrefix "#" c.fg})";
            check_color = "rgb(${lib.removePrefix "#" c.blue})";
            fail_color = "rgb(${lib.removePrefix "#" c.red})";
            capslock_color = "rgb(${lib.removePrefix "#" c.yellow})";
            dots_center = true;
            fade_on_empty = true;
            fade_timeout = 10000;
            placeholder_text = "";
          }
        ];
      };
    };
  };
}
