{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    delta
    difftastic
    eza
    gcc
    ghq
    git-lfs
    gnumake
    lsd
    ripgrep
    unzip
    zoxide
  ];
}
