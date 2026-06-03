''
  Mod+Shift+Slash { show-hotkey-overlay; }

  Mod+Return { spawn "wezterm"; }
  Mod+T { spawn "wezterm"; }
  Alt+Space { spawn "vicinae" "open"; }
  Mod+V { spawn "vicinae" "deeplink" "vicinae://launch/clipboard/history"; }
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
''
