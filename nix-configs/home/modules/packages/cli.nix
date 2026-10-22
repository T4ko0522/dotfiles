{
  lib,
  localPackages,
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      bat
      btop
      cloudflared
      delta
      difftastic
      diffnav
      doggo
      dust
      eza
      gcc
      gh
      ghq
      gnumake
      gping
      gtop
      git-secrets
      just
      lsd
      ripgrep
      unzip
    ]
    ++ [localPackages.cfCli]
    ++ lib.optionals stdenv.hostPlatform.isLinux [spotify-cli];
}
