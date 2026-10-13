{
  config,
  dotfilesPath,
  lib,
  localPackages ? {},
  pkgs,
  ...
}: {
  fonts.fontconfig.enable = pkgs.stdenv.isLinux;

  home.packages = lib.optionals pkgs.stdenv.isLinux [localPackages.lineSeedJp];

  xdg.configFile."zed".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/zed/files";
}
