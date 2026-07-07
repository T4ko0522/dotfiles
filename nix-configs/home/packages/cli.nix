{pkgs, ...}: {
  home.packages = with pkgs; [
    # actrun
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
