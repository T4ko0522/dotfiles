{pkgs, ...}: {
  services.displayManager = {
    defaultSession = "niri";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [pkgs.sddm-astronaut];
    };
  };

  environment.systemPackages = [pkgs.sddm-astronaut];
}
