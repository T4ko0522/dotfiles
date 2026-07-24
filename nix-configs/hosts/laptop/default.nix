{
  imports = [
    ./hardware-configuration.nix
    ../../feature/profiles/workstation.nix
    ../../feature/modules/desktop/plymouth.nix
    ../../feature/modules/hardware/nvidia-hybrid.nix
    ../../feature/profiles/gaming.nix
    # ../../feature/profiles/vr.nix
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
