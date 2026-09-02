{
  codex-desktop-linux,
  llm-agents,
  localPackages,
  pkgs,
  ...
}: let
  codexPackage = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  codexDesktopBasePackage = codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop.override {
    linuxFeatureIds = ["pet-overlay"];
  };
  codexDesktopPackage = pkgs.callPackage ../../../pkgs/codex-desktop/package.nix {
    basePackage = codexDesktopBasePackage;
  };
in {
  programs.codexDesktopLinux = {
    enable = true;
    package = codexDesktopPackage;
    cliPackage = codexPackage;
  };

  home.file = {
    ".codex/pets/reimu/pet.json".source = "${localPackages.codexPetReimu}/pet.json";
    ".codex/pets/reimu/spritesheet.webp".source = "${localPackages.codexPetReimu}/spritesheet.webp";
  };
}
