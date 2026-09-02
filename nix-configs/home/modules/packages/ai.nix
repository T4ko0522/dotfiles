{
  llm-agents,
  pkgs,
  ...
}: {
  home.packages = with llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    claude-code
    codex
    opencode
  ];
}
