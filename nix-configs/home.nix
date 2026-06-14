{...}: {
  imports = [
    ./home/base.nix
    ./home/profiles/cursor.nix
    ./home/packages.nix
    ./home/xdg.nix
    ./home/niri.nix
    ./home/wallpaper.nix
    ./home/swaync.nix
    ./home/waybar.nix
    ./home/razer.nix
    ./home/vr.nix
    ./home/zsh.nix
    ./home/programs.nix
    ./home/firefox.nix
    ./home/vicinae.nix
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
