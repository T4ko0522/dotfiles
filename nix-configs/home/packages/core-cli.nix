{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    fastfetch
    fd
    fzf
    jq
    lazygit
    nil
    peco
    starship
    tree-sitter
    vim
    yazi
  ];
}
