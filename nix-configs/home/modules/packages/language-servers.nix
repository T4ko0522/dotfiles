{pkgs, ...}: {
  home.packages = with pkgs; [
    biome
    docker-compose-language-service
    dockerfile-language-server
    gofumpt
    gopls
    gotools
    marksman
    nixfmt
    prettier
    pyright
    ruff
    statix
    stylua
    taplo
    tailwindcss-language-server
    vscode-langservers-extracted
    vtsls
  ];
}
