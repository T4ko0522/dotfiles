{
  config,
  dotfilesPath,
  localPackages,
  ...
}: {
  fonts.fontconfig.enable = true;

  home.packages = [localPackages.lineSeedJp];

  xdg.configFile."zed".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/zed/files";
}
