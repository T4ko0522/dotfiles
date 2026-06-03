{
  imports = [
    ./hardware-configuration.nix
    ./modules
    ./profiles/desktop.nix
    ./profiles/nvidia.nix
    ./profiles/gaming.nix
    ./profiles/desktop-apps.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
