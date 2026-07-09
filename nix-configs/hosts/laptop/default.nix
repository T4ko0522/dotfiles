{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../profiles/desktop.nix
    ../../profiles/nvidia-hybrid.nix
    ../../profiles/gaming.nix
    # ../../profiles/vr.nix
    ../../profiles/desktop-apps.nix
  ];

  networking.hostName = "laptop";

  services.pipewire.wireplumber.extraConfig.bluetooth = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = false;
    };

    "monitor.bluez.properties" = {
      "bluez5.roles" = [
        "a2dp_sink"
        "a2dp_source"
      ];
    };
  };

  home-manager.users.t4ko.t4ko.niri.monitors = {
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
