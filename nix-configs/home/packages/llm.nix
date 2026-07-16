{
  claudex,
  pkgs,
  ...
}: let
  claudexPackage = pkgs.callPackage ../../pkgs/claudex/package.nix {src = claudex;};
in {
  home.packages = with pkgs.llm-agents; [
    claude-code
    claudexPackage
    codex
    opencode
    apm
  ];
}
