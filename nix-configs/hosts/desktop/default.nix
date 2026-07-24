{
  imports = [
    ./hardware-configuration.nix
    ../../feature/profiles/workstation.nix
    ../../feature/modules/hardware/lanzaboote.nix
    ../../feature/modules/desktop/plymouth.nix
    ../../feature/modules/hardware/nvidia.nix
    ../../feature/profiles/gaming.nix
    ../../feature/profiles/vr.nix
  ];

  networking.hostName = "desktop";
  system.stateVersion = "26.05";

  t4ko.regreet.mainOutput = "DP-2";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
