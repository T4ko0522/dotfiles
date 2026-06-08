{
  config,
  lib,
  keyboardLayout,
  ...
}: let
  c = import ../lib/catppuccin-mocha.nix;
  cfg = config.t4ko.niri;

  renderMonitor = name: output: let
    parts =
      lib.optional (output.position != null)
        "    position x=${toString output.position.x} y=${toString output.position.y}"
      ++ lib.optional (output.transform != null)
        "    transform \"${output.transform}\"";
  in
    lib.optionalString (parts != []) (
      "output \"${name}\" {\n"
      + lib.concatMapStrings (p: p + "\n") parts
      + "}\n\n"
    );
in {
  options.t4ko.niri.monitors = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        position = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              x = lib.mkOption {
                type = lib.types.int;
                default = 0;
              };
              y = lib.mkOption {
                type = lib.types.int;
                default = 0;
              };
            };
          });
          default = null;
          description = "Monitor position.";
        };
        transform = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Monitor transform (rotation), e.g. \"90\".";
        };
      };
    });
    default = {};
    description = "Per-output niri monitor configuration.";
  };

  config.xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "${keyboardLayout.xkbLayout}"
                model "${keyboardLayout.xkbModel}"
            }
        }

        touchpad {
            tap
            natural-scroll
        }
    }

    layout {
        gaps 14
        center-focused-column "on-overflow"
        always-center-single-column
        background-color "${c.crust}"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            off
        }

        border {
            width 3
            active-gradient from="${c.blue}" to="${c.lavender}" angle=45 relative-to="workspace-view"
            inactive-color "${c.surface}"
            urgent-color "${c.red}"
        }

        shadow {
            on
            softness 32
            spread 4
            offset x=0 y=6
            color "#00000070"
            inactive-color "#00000048"
        }

        tab-indicator {
            hide-when-single-tab
            place-within-column
            gap 6
            width 4
            length total-proportion=1.0
            position "top"
            gaps-between-tabs 2
            corner-radius 8
            active-color "${c.lavender}"
            inactive-color "${c.surface1}"
            urgent-color "${c.red}"
        }

        insert-hint {
            gradient from="${c.blue}80" to="${c.lavender}80" angle=45 relative-to="workspace-view"
        }

        struts {
            left 4
            right 4
            bottom 4
        }
    }

    ${lib.concatStrings (lib.mapAttrsToList renderMonitor cfg.monitors)}
    prefer-no-csd

    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
    }

    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "swaync"
    ${config.t4ko.wallpaper.niriSpawnCommand}

    environment {
        DISPLAY ":0"
    }

    binds {
      ${import ./niri-keybind.nix}
    }
  '';
}
