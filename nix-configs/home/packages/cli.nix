{pkgs, ...}: {
  home.packages = with pkgs; [
    bat
    delta
    difftastic
    doggo
    eza
    gcc
    ghq
    git-lfs
    gnumake
    gping
    gtop
    just
    lsd
    ripgrep
    unzip
    zoxide
  ];
}
