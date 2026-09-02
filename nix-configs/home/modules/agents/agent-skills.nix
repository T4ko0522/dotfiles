{
  agent-skills,
  actrun,
  config,
  lib,
  mizchi-skills,
  ...
}: let
  agentLib = agent-skills.lib.agent-skills;
in {
  home.activation.prepareAgentSkillsTargets = lib.hm.dag.entryBetween ["agent-skills"] ["writeBoundary"] ''
    targets=(
      "${config.home.homeDirectory}/.agents/skills"
      "''${CLAUDE_CONFIG_DIR:-${config.home.homeDirectory}/.claude}/skills"
      "''${CODEX_HOME:-${config.home.homeDirectory}/.codex}/skills"
      "${config.home.homeDirectory}/.config/opencode/skills"
    )

    for target in "''${targets[@]}"; do
      if { [ -e "$target" ] || [ -L "$target" ]; } \
        && [ ! -e "$target/.agent-skills-managed.json" ]; then
        export AGENT_SKILLS_FORCE=1
        break
      fi
    done
  '';

  programs.agent-skills = {
    enable = true;

    sources = {
      local.path = ./files/skills;
      mizchi = {
        path = mizchi-skills;
        subdir = ".";
      };
      actrun = {
        path = actrun;
        subdir = ".claude/skills";
      };
    };

    skills.explicit = {
      tool-pipeline = {
        from = "local";
        path = "tool-pipeline";
      };
      markdown-session-format = {
        from = "local";
        path = "markdown-session-format";
      };
      git-commit = {
        from = "local";
        path = "git-commit";
      };
      github-thread-fetcher = {
        from = "local";
        path = "github-thread-fetcher";
      };
      pr-summarizer = {
        from = "local";
        path = "pr-summarizer";
      };
      nix-setup = {
        from = "mizchi";
        path = "tooling/nix-setup";
      };
      justfile = {
        from = "mizchi";
        path = "tooling/justfile";
      };
      conventional-changelog = {
        from = "mizchi";
        path = "tooling/conventional-changelog";
      };
      gh-fix-ci = {
        from = "mizchi";
        path = "devops/gh-fix-ci";
      };
      deploy = {
        from = "mizchi";
        path = "cloudflare/deploy";
      };
      workers-otel-utels = {
        from = "mizchi";
        path = "cloudflare/workers-otel-utels";
      };
      actrun = {
        from = "actrun";
        path = "actrun";
      };
    };

    targets = {
      agents = agentLib.defaultTargets.agents // {enable = true;};
      claude = agentLib.defaultTargets.claude // {enable = true;};
      codex = agentLib.defaultTargets.codex // {enable = true;};
      opencode = agentLib.defaultTargets.opencode // {enable = true;};
    };
  };
}
