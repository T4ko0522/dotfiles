{
  codex-desktop-linux,
  localPackages,
  pkgs,
  ...
}: let
  codexDesktopBasePackage = codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  codexDesktopPackage = pkgs.callPackage ../../../pkgs/codex-desktop/package.nix {
    basePackage = codexDesktopBasePackage;
  };
in {
  programs.codexDesktopLinux = {
    enable = true;
    package = codexDesktopPackage;
  };

  home.file = {
    ".codex/pets/reimu/pet.json".source = "${localPackages.codexPetReimu}/pet.json";
    ".codex/pets/reimu/spritesheet.webp".source = "${localPackages.codexPetReimu}/spritesheet.webp";
  };
}
