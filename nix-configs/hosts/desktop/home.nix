{dotfilesPath, ...}: {
  imports = [
    ../../home/profiles/workstation.nix
    ../../home/modules/desktop/galleria-case-lighting.nix
  ];

  t4ko.appPresets.startup.apps = [
    {
      name = "Spotify";
      command = ["spotify"];
      matcher.appId = "^spotify$";
      output = "DP-2";
      workspace = 1;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "Google Chrome";
      command = ["google-chrome"];
      matcher.appId = "^google-chrome$";
      output = "DP-2";
      workspace = 1;
      column = 2;
      columnWidth = 100;
    }
    {
      name = "Proton Pass";
      command = ["proton-pass"];
      matcher.appId = "^proton-pass$";
      output = "DP-2";
      workspace = 1;
      column = 3;
      columnWidth = 50;
    }
    {
      name = "Zed";
      command = ["zeditor" dotfilesPath];
      matcher.appId = "^dev\\.zed\\.Zed$";
      output = "DP-2";
      workspace = 2;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "WezTerm";
      command = ["wezterm"];
      matcher.appId = "^org\\.wezfurlong\\.wezterm$";
      output = "DP-2";
      workspace = 2;
      column = 2;
      columnWidth = 100;
    }
    {
      name = "Codex";
      command = ["codex-desktop"];
      matcher.appId = "^codex-desktop$";
      output = "DP-2";
      workspace = 3;
      column = 1;
      columnWidth = 100;
    }
    {
      name = "Brave";
      command = ["brave"];
      matcher.appId = "^brave-browser$";
      output = "DP-2";
      workspace = 3;
      column = 2;
      columnWidth = 100;
    }
    {
      name = "Vesktop";
      command = ["vesktop"];
      matcher.appId = "^vesktop$";
      output = "HDMI-A-1";
      workspace = 1;
      column = 1;
      columnWidth = 100;
    }
  ];

  t4ko.niri.monitors = {
    "DP-1" = {
      mode = "1920x1080@144.000";
      position = {
        x = 3840;
        y = -840;
      };
      transform = "90";
    };
    "DP-2" = {
      focusAtStartup = true;
      mode = "1920x1080@360.000";
      position = {
        x = 0;
        y = 0;
      };
    };
    "HDMI-A-1" = {
      mode = "1920x1080@75.000";
      position = {
        x = 1920;
        y = 0;
      };
    };
  };
}
