{
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../linux/profiles/workstation.nix
    ../../linux/modules/hardware/lanzaboote.nix
    ../../linux/modules/desktop/plymouth.nix
    ../../linux/modules/hardware/nvidia.nix
    ../../linux/profiles/gaming.nix
    ../../linux/profiles/vr.nix
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
