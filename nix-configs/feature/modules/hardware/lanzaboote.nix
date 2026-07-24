{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sbctl
  ];

  boot = {
    # Lanzaboote manages the systemd-boot compatible boot entries itself.
    loader.systemd-boot.enable = lib.mkForce false;

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
