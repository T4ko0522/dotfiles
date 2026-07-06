{pkgs, ...}: {
  home.packages = with pkgs.llm-agents; [
    claude-code
    codex
    opencode
    pkgs.apm-cli
  ];
}
