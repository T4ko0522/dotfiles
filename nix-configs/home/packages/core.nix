{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    fastfetch
    fd
    fzf
    ghostty
    jq
    lazygit
    nil
    peco
    starship
    tree-sitter
    vim
    wezterm
    yazi
    zed-editor
  ];
}
