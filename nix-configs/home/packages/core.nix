{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    fastfetch
    fd
    fzf
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
  ];
}
