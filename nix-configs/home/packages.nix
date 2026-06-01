{...}: {
  imports = [
    ./packages/core.nix
    ./packages/cli.nix
    ./packages/development.nix
    ./packages/lsp.nix
    ./packages/llm.nix
    ./packages/media.nix
    ./packages/wayland.nix
  ];
}
