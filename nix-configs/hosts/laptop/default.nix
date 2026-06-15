{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../profiles/desktop.nix
    ../../profiles/nvidia.nix
    ../../profiles/gaming.nix
    # ../../profiles/vr.nix
    ../../profiles/desktop-apps.nix
  ];

  networking.hostName = "laptop";

  home-manager.users.t4ko.t4ko.niri.monitors = {
    "HDMI-A-1" = {
      mode = "1920x1080@60.000";
      position = {
        x = 0;
        y = 0;
      };
    };
    "eDP-1" = {
      mode = "1920x1080@165.016";
      position = {
        x = 1920;
        y = 0;
      };
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
