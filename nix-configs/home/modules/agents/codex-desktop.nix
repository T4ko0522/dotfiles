{
  codex-desktop-linux,
  llm-agents,
  pkgs,
  ...
}: let
  codexPackage = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  codexDesktopPackage = pkgs.callPackage ../../../pkgs/codex-desktop/package.nix {
    basePackage = codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  };
in {
  programs.codexDesktopLinux = {
    enable = true;
    package = codexDesktopPackage;
    cliPackage = codexPackage;
  };
}
