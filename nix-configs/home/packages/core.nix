{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    fastfetch
    fd
    fzf
    ghostty
    jq
    lazygit
    neovim
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
