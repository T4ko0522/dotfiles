{
  config,
  lib,
  keyboardLayout,
  ...
}: let
  c = import ../../../lib/theme.nix;
  cfg = config.t4ko.niri;
  quickShell = config.t4ko.quickShell;
  lockscreenCommand = lib.getExe config.t4ko.lockscreen.command;
  quickShellAppIdRegex = lib.replaceStrings ["\\"] ["\\\\"] (lib.escapeRegex quickShell.appId);

  renderMonitor = name: output: let
    parts =
      lib.optional output.focusAtStartup "    focus-at-startup"
      ++ lib.optional (output.mode != null) "    mode \"${output.mode}\""
      ++ lib.optional (
        output.position != null
      ) "    position x=${toString output.position.x} y=${toString output.position.y}"
      ++ lib.optional (output.transform != null) "    transform \"${output.transform}\"";
  in
    lib.optionalString (parts != []) (
      "output \"${name}\" {\n" + lib.concatMapStrings (p: p + "\n") parts + "}\n\n"
    );
in {
  options.t4ko.niri.monitors = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          position = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
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
              }
            );
            default = null;
            description = "Monitor position.";
          };
          transform = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Monitor transform (rotation), e.g. \"90\".";
          };
          mode = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Monitor mode, e.g. \"1920x1080@144.000\".";
          };
          focusAtStartup = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Focus this output at startup (acts as the main monitor).";
          };
        };
      }
    );
    default = {};
    description = "Per-output niri monitor configuration.";
  };

  config.xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "${keyboardLayout.xkbLayout}"
                model "${keyboardLayout.xkbModel}"
                options "${keyboardLayout.xkbOptions}"
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
            width 4.6
            active-gradient from="${c.mauve}" to="${c.lavender}" angle=45 relative-to="workspace-view"
            inactive-color "#00000000"
            urgent-color "${c.red}"
        }

        border {
            off
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
    animations {
        window-open {
            spring damping-ratio=0.82 stiffness=500 epsilon=0.0001
        }
        window-close {
            spring damping-ratio=1.0 stiffness=600 epsilon=0.0001
        }
        window-movement {
            spring damping-ratio=0.8 stiffness=450 epsilon=0.0001
        }
        window-resize {
            spring damping-ratio=0.85 stiffness=550 epsilon=0.0001
        }
        horizontal-view-movement {
            spring damping-ratio=0.8 stiffness=450 epsilon=0.0001
        }
        workspace-switch {
            spring damping-ratio=0.85 stiffness=500 epsilon=0.0001
        }
        overview-open-close {
            spring damping-ratio=0.82 stiffness=600 epsilon=0.0001
        }
    }

    prefer-no-csd

    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
    }

    window-rule {
        match app-id="^${quickShellAppIdRegex}$"

        open-floating true
        open-focused true
        default-column-width { fixed 1200; }
        default-window-height { fixed 420; }
        default-floating-position x=0 y=120 relative-to="top"

        focus-ring {
            off
        }
    }

    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "sh" "-c" "sleep 2 && fcitx5 -rd"
    spawn-at-startup "swaync"
    ${config.t4ko.wallpaper.niriSpawnCommand}

    environment {
        DISPLAY ":0"
    }

    binds {
      ${import ./niri-keybind.nix {
      quickShellCommand = quickShell.command;
      quickShellModFCommand = quickShell.modFCommand;
      inherit lockscreenCommand;
    }}
    }
  '';
}
