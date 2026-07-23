{pkgs, ...}: {
  home.packages = with pkgs; [
    # actrun
    bat
    chezmoi
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
    just
    lsd
    ripgrep
    spotify-cli
    unzip
    zoxide
  ];
}
