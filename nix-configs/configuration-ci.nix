{
  imports = [
    ./hosts/desktop/hardware-configuration.nix
    ./modules
  ];

  networking.hostName = "nixos";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
