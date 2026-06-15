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
    spotify-cli
    unzip
    zoxide
  ];
}
