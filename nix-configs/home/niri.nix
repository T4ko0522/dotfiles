{
  config,
  keyboardLayout,
  ...
}:
{
  xdg.configFile."niri/config.kdl".text = ''
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
        background-color "#11111b"

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
            active-gradient from="#89b4fa" to="#b4befe" angle=45 relative-to="workspace-view"
            inactive-color "#313244"
            urgent-color "#f38ba8"
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
            active-color "#b4befe"
            inactive-color "#45475a"
            urgent-color "#f38ba8"
        }

        insert-hint {
            gradient from="#89b4fa80" to="#b4befe80" angle=45 relative-to="workspace-view"
        }

        struts {
            left 4
            right 4
            bottom 4
        }
    }

    output "DP-1" {
        position x=3840 y=-840
        transform "90"
    }

    output "DP-2" {
        position x=0 y=0
    }

    output "HDMI-A-1" {
        position x=1920 y=0
    }

    prefer-no-csd

    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
    }

    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "fcitx5" "-d"
    ${config.t4ko.wallpaper.niriSpawnCommand}

    environment {
        DISPLAY ":0"
    }

    binds {
      ${import ./niri-keybind.nix}
    }
  '';
}
