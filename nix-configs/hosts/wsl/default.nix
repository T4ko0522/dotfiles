{username, ...}: {
  imports = [
    ../../feature/profiles/wsl.nix
  ];

  networking.hostName = "nixos-wsl";

  wsl = {
    enable = true;
    defaultUser = username;
    interop.includePath = true;
    wslConf = {
      automount = {
        enabled = true;
        options = "metadata,umask=22,fmask=11";
      };
      boot.systemd = true;
      interop = {
        enabled = true;
        appendWindowsPath = true;
      };
      user.default = username;
    };
  };

  system.stateVersion = "26.05";
}
