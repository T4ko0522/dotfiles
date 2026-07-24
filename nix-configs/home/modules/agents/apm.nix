{
  config,
  lib,
  llm-agents,
  pkgs,
  ...
}: let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in {
  home = {
    file.".claude/skills".source = link "mutable/shared/apm/.claude/skills";

    activation = {
      apmInstallSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
        cd "${config.home.homeDirectory}/dotfiles/mutable/shared/apm"
        export GITHUB_TOKEN="$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)"
        ${llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.apm}/bin/apm install
      '';

      linkCodexSkills = lib.hm.dag.entryAfter ["apmInstallSkills"] ''
        source_dir="${config.home.homeDirectory}/dotfiles/mutable/shared/apm/.agents/skills"
        target_dir="${config.home.homeDirectory}/.codex/skills"
        mkdir -p "$target_dir"
        find "$target_dir" -maxdepth 1 -type l -lname "$source_dir/*" -delete
        for skill in "$source_dir"/*; do
          [ -d "$skill" ] || continue
          ln -sfn "$skill" "$target_dir/$(basename "$skill")"
        done
      '';

      linkOpencodeSkills = lib.hm.dag.entryAfter ["apmInstallSkills"] ''
        source_dir="${config.home.homeDirectory}/dotfiles/mutable/shared/apm/.agents/skills"
        target_dir="${config.home.homeDirectory}/.config/opencode/skills"
        mkdir -p "$target_dir"
        find "$target_dir" -maxdepth 1 -type l -lname "$source_dir/*" -delete
        for skill in "$source_dir"/*; do
          [ -d "$skill" ] || continue
          ln -sfn "$skill" "$target_dir/$(basename "$skill")"
        done
      '';
    };
  };
}
