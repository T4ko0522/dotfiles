{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      bat
      delta
      difftastic
      diffnav
      doggo
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
    ++ lib.optionals stdenv.hostPlatform.isLinux [spotify-cli];
}
