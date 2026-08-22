{
  imports = [../../home/profiles/workstation.nix];

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
