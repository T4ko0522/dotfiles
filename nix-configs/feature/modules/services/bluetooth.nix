{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        DeviceID = "bluetooth:004C:0000:0000";
      };
    };
  };

  services.pipewire.wireplumber.extraConfig.bluetooth = {
    "monitor.bluez.properties" = {
      "bluez5.dummy-avrcp-player" = true;
    };
  };

  services.blueman.enable = true;
}
