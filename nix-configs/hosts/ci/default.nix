{
  imports = [
    ../desktop/hardware-configuration.nix
    ../../feature/profiles/base.nix
    ../../feature/modules/hardware/kernel.nix
    ../../feature/modules/hardware/qmk.nix
    ../../feature/modules/hardware/xkb.nix
    ../../feature/modules/services/bluetooth.nix
    ../../feature/modules/services/docker.nix
    ../../feature/modules/services/networkmanager.nix
    ../../feature/modules/services/tailscale.nix
  ];

  networking.hostName = "nixos";
  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
