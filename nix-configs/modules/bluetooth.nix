{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.pipewire.wireplumber.extraConfig.bluetooth = {
    "monitor.bluez.properties" = {
      "bluez5.dummy-avrcp-player" = true;
    };
  };

  services.blueman.enable = true;
}
