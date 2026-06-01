{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    delta
    difftastic
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    gcc
    ghq
    git-lfs
    gnumake
    gomi
    jq
    just
    lazygit
    lsd
    marksman
    neovim
    nil
    nixfmt
    peco
    ripgrep
    starship
    statix
    tailwindcss-language-server
    tree-sitter
    unzip
    waybar
    wezterm
    wl-clipboard
    xdg-utils
    yazi
    zoxide

    # LSP servers (Mason経由ではなくNix管理)
    biome
    docker-compose-language-service
    dockerfile-language-server-nodejs
    gopls
    gofumpt
    gotools # goimports含む
    markdownlint-cli2
    prettier
    pyright
    ruff
    vscode-langservers-extracted # json-lsp / eslint-lsp含む
    vtsls
  ];
}
