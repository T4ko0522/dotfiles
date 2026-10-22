{pkgs}: {
  cfCli = pkgs.callPackage ./cf-cli/package.nix {};
  codexPetReimu = pkgs.callPackage ./codex-pets/reimu.nix {};
  lineSeedJp = pkgs.callPackage ./line-seed-jp/package.nix {};
  vimdocJa = pkgs.callPackage ./vim-plugins/vimdoc-ja/package.nix {};
  vitePlus = pkgs.callPackage ./vite-plus/package.nix {};
  winresizer = pkgs.callPackage ./vim-plugins/winresizer/package.nix {};
}
