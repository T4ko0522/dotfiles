_: {
  networking.networkmanager.enable = true;

  # Activation and resolver updates can restart nscd several times in 10 seconds.
  systemd.services.nscd.unitConfig.StartLimitBurst = 20;
}
