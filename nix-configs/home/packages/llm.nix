{
  llm-agents,
  pkgs,
  ...
}: {
  home.packages = with llm-agents.packages.${pkgs.system}; [
    claude-code
    codex
    opencode
    apm
  ];
}
