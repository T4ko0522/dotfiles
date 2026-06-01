{
  ciBuild ? false,
  lib,
  ...
}: {
  imports =
    [
      ./packages/core.nix
      ./packages/cli.nix
    ]
    ++ lib.optionals (!ciBuild) [
      ./packages/development.nix
      ./packages/lsp.nix
      ./packages/llm.nix
      ./packages/media.nix
      ./packages/wayland.nix
    ];
}
