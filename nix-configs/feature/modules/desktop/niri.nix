{
  programs.niri.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;
  hardware.graphics.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
