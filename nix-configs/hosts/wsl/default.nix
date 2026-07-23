{username, ...}: {
  imports = [
    ../../modules/nh.nix
    ../../modules/nix.nix
    ../../modules/unfree.nix
    ../../modules/users.nix
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

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";
}
