{
  config,
  lib,
  pkgs,
  ...
}: let
  configTemplate = pkgs.writeText "config.toml" (
    builtins.replaceStrings ["/home/t4ko"] [config.home.homeDirectory]
    (builtins.readFile ./files/codex/config.toml)
  );
in {
  home.activation.seedCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    codex_cfg="${config.home.homeDirectory}/.codex/config.toml"
    codex_tmpl="${configTemplate}"
    mkdir -p "${config.home.homeDirectory}/.codex"
    if [ -L "$codex_cfg" ] || [ ! -e "$codex_cfg" ]; then
      rm -f "$codex_cfg"
      cp "$codex_tmpl" "$codex_cfg"
      chmod u+w "$codex_cfg"
    fi
  '';

  home.file = {
    ".codex/AGENTS.md".source = ./files/codex/AGENTS.md;
    ".codex/agents".source = ./files/codex/agents;
    ".codex/rules".source = ./files/codex/rules;
  };
}
