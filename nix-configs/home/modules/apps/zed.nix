{
  config,
  dotfilesPath,
  ...
}: {
  xdg.configFile."zed".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/zed/files";
}
