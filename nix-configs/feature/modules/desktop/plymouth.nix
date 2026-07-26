{
  lib,
  localPackages,
  ...
}: let
  themeName = "nixos-loading-default-logs";
in {
  boot = {
    plymouth.nixos-loading = {
      enable = true;
      variant = "default";
    };
    plymouth = {
      theme = lib.mkForce themeName;
      themePackages = lib.mkForce [localPackages.plymouthTheme];
    };

    consoleLogLevel = 7;
    initrd.verbose = true;

    kernelParams = [
      "rd.udev.log_level=info"
      "rd.systemd.show_status=true"
      "udev.log_level=info"
      "systemd.show_status=true"
    ];
  };
}
