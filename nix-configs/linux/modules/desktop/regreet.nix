{
  config,
  keyboardLayout,
  lib,
  pkgs,
  ...
}: let
  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    variant = "mocha";
  };
  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-nineish.png";
    hash = "sha256-EMSD1XQLaqHs0NbLY0lS1oZ4rKznO+h9XOGDS121m9c=";
  };
  cfg = config.t4ko.regreet;
in {
  options.t4ko.regreet.mainOutput = lib.mkOption {
    type = lib.types.str;
    description = "Output on which ReGreet is displayed.";
  };

  config = {
    programs.regreet = {
      enable = true;

      theme = {
        package = catppuccinGtk;
        name = "catppuccin-mocha-blue-standard";
      };

      settings = {
        background = {
          path = "${wallpaper}";
          fit = "Cover";
        };

        GTK.application_prefer_dark_theme = true;

        commands = {
          reboot = ["${pkgs.systemd}/bin/systemctl" "--no-block" "reboot"];
          poweroff = ["${pkgs.systemd}/bin/systemctl" "--no-block" "poweroff"];
        };

        widget.clock = {
          format = "%Y年%m月%d日 (%a)  %H:%M";
          resolution = "1s";
          locale = "ja_JP.UTF-8";
        };
      };
    };

    services.greetd.settings.default_session = {
      command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.niri}/bin/niri --config /etc/greetd/niri.kdl -- ${lib.getExe config.programs.regreet.package}";
      user = "greeter";
    };

    systemd.services.greetd = {
      environment = {
        RUST_BACKTRACE = "1";
        RUST_LOG = "greetd=debug";
      };
      serviceConfig.LogLevelMax = "debug";
    };

    environment.etc."greetd/niri.kdl".text = ''
        input {
          keyboard {
            xkb {
              layout "${keyboardLayout.xkbLayout}"
              model "${keyboardLayout.xkbModel}"
              options "${keyboardLayout.xkbOptions}"
            }
          }
        }

        output "${cfg.mainOutput}" {
          focus-at-startup
        }

      window-rule {
        match app-id="^apps\\.regreet$"
        open-on-output "${cfg.mainOutput}"
        open-maximized true
        open-focused true
      }
    '';
  };
}
