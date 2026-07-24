{
  imports = [../../home/profiles/workstation.nix];

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
