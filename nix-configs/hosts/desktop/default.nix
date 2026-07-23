{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../modules/lanzaboote.nix
    ../../modules/plymouth.nix
    ../../profiles/desktop.nix
    ../../profiles/nvidia.nix
    ../../profiles/gaming.nix
    ../../profiles/vr.nix
    ../../profiles/desktop-apps.nix
  ];

  networking.hostName = "desktop";
  system.stateVersion = "26.05";

  t4ko.regreet.mainOutput = "DP-2";

  home-manager.users.t4ko.t4ko.niri.monitors = {
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
