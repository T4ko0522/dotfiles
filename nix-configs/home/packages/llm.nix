{
  claudex,
  llm-agents,
  pkgs,
  ...
}: let
  claudexPackage = pkgs.callPackage ../../pkgs/claudex/package.nix {src = claudex;};
in {
  home.packages = with llm-agents.packages.${pkgs.system}; [
    claude-code
    claudexPackage
    codex
    opencode
    apm
  ];
}
