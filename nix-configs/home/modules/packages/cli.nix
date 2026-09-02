{pkgs, ...}: {
  home.packages = with pkgs; [
    bat
    delta
    difftastic
    diffnav
    doggo
    eza
    gcc
    ghq
    git-lfs
    gnumake
    gping
    gtop
    gh-dash
    git
    git-secrets
    just
    lsd
    ripgrep
    spotify-cli
    unzip
    zoxide
  ];
}
