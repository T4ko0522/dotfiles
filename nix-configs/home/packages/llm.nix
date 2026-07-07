{pkgs, ...}: {
  home.packages = with pkgs.llm-agents; [
    claude-code
    codex
    opencode
    apm
  ];
}
