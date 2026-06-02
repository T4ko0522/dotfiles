{keyboardLayout, ...}: {
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

    prefer-no-csd

    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
    }

    spawn-at-startup "waybar"
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "linux-wallpaperengine" "--assets-dir" "/home/t4ko/.local/share/Steam/steamapps/common/wallpaper_engine" "--screen-root" "DP-2" "--bg" "1810612745" "--screen-root" "HDMI-A-1" "--bg" "1810612745"

    environment {
        DISPLAY ":0"
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+Return { spawn "wezterm"; }
        Mod+T { spawn "wezterm"; }
        Mod+D { spawn "sh" "-c" "fuzzel || true"; }
        Mod+Q { close-window; }

        Mod+Left { focus-column-left; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H { focus-column-left; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+L { focus-column-right; }

        Mod+Ctrl+Left { move-column-left; }
        Mod+Ctrl+Down { move-window-down; }
        Mod+Ctrl+Up { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+J { move-window-down; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Shift+H { move-window-to-monitor-left; }
        Mod+Shift+L { move-window-to-monitor-right; }

        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up { move-column-to-workspace-up; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+R { switch-preset-column-width; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+C { center-column; }
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }

        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

        Mod+Shift+E { quit; }
        Mod+Shift+P { power-off-monitors; }
    }
  '';
}
