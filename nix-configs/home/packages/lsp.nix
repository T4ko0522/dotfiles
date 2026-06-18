{pkgs, ...}: {
  home.packages = with pkgs; [
    biome
    docker-compose-language-service
    dockerfile-language-server
    gofumpt
    gopls
    gotools
    markdownlint-cli2
    marksman
    nixfmt
    prettier
    pyright
    ruff
    statix
    stylua
    tailwindcss-language-server
    vscode-langservers-extracted
    vtsls
  ];
}
