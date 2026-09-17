{pkgs, ...}: {
  home.packages = with pkgs; [
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
    spotify-cli
    unzip
  ];
}
