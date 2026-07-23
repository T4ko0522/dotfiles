{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../modules/plymouth.nix
    ../../profiles/desktop.nix
    ../../profiles/nvidia-hybrid.nix
    ../../profiles/gaming.nix
    # ../../profiles/vr.nix
    ../../profiles/desktop-apps.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "26.05";

  t4ko.regreet.mainOutput = "HDMI-A-1";

  services.pipewire.wireplumber.extraConfig.bluetooth = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = false;
    };

    "monitor.bluez.properties" = {
      "bluez5.roles" = [
        "a2dp_sink"
        "a2dp_source"
        "bap_sink"
        "bap_source"
        "hfp_hf"
        "hfp_ag"
        "hsp_hs"
        "hsp_ag"
      ];
      "bluez5.hfphsp-backend" = "native";
    };

    "monitor.bluez.rules" = [
      {
        matches = [
          {
            "device.name" = "bluez_card.F8_1E_49_E1_E7_4B";
          }
        ];
        actions.update-props = {
          "device.profile" = "a2dp-sink";
        };
      }
    ];
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
