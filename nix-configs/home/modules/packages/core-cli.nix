{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    fastfetch
    fd
    jq
    lazygit
    nil
    peco
    tree-sitter
    yazi
  ];
}
