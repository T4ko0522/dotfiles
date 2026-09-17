{dotfilesPath, ...}: {
  imports = [../../home/profiles/workstation.nix];

  t4ko.appPresets.startup.apps = [
    {
      name = "Vesktop";
      command = ["vesktop"];
      matcher.appId = "^vesktop$";
      output = "eDP-1";
      workspace = 1;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "Google Chrome";
      command = ["google-chrome"];
      matcher.appId = "^google-chrome$";
      output = "eDP-1";
      workspace = 1;
      column = 2;
      columnWidth = 100;
    }
    {
      name = "LibrePods";
      command = ["librepods"];
      matcher = {
        appId = "^$";
        title = "^LibrePods$";
      };
      output = "eDP-1";
      workspace = 1;
      column = 3;
      columnWidth = 66.667;
    }
    {
      name = "WezTerm";
      command = ["wezterm"];
      matcher.appId = "^org\\.wezfurlong\\.wezterm$";
      output = "HDMI-A-1";
      workspace = 1;
      column = 1;
      columnWidth = 50;
    }
    {
      name = "Zed";
      command = ["zeditor" dotfilesPath];
      matcher.appId = "^dev\\.zed\\.Zed$";
      output = "HDMI-A-1";
      workspace = 1;
      column = 2;
      columnWidth = 50;
    }
    {
      name = "Brave";
      command = ["brave"];
      matcher.appId = "^brave-browser$";
      output = "eDP-1";
      workspace = 2;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "Spotify";
      command = ["spotify"];
      matcher.appId = "^spotify$";
      output = "eDP-1";
      workspace = 2;
      column = 2;
      columnWidth = 100;
    }
    {
      name = "Codex";
      command = ["codex-desktop"];
      matcher.appId = "^codex-desktop$";
      output = "HDMI-A-1";
      workspace = 2;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "Steam";
      command = ["steam"];
      matcher.appId = "^steam$";
      output = "eDP-1";
      workspace = 3;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "Wallpaper UI";
      command = ["steam" "steam://rungameid/431960"];
      matcher = {
        appId = "^steam_app_431960$";
        title = "^Wallpaper UI$";
      };
      output = "HDMI-A-1";
      workspace = 1;
      column = 3;
      columnWidth = 50;
    }
  ];

  t4ko.niri.monitors = {
    "eDP-1" = {
      mode = "1920x1080@165.016";
      position = {
        x = 0;
        y = 0;
      };
    };
    "HDMI-A-1" = {
      focusAtStartup = true;
      mode = "1920x1080@60.000";
      position = {
        x = 1920;
        y = 0;
      };
    };
  };

  t4ko.wallpaper.monitors = [
    "HDMI-A-1"
    "eDP-1"
  ];
}
