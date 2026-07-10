{...}: {
  boot = {
    plymouth.nixos-loading = {
      enable = true;
      variant = "default";
    };

    consoleLogLevel = 3;
    initrd.verbose = false;

    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };
}
