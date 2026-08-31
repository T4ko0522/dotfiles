{
  config,
  lib,
  ...
}: {
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

  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  systemd.services.openrgb.serviceConfig.ExecStart = lib.mkForce (lib.escapeShellArgs [
    (lib.getExe config.services.hardware.openrgb.package)
    "--server"
    "--server-host"
    "127.0.0.1"
    "--server-port"
    (toString config.services.hardware.openrgb.server.port)
  ]);
}
