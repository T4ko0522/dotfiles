{
  config,
  dotfilesPath,
  ...
}: {
  xdg.configFile."karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/karabiner/files/karabiner.json";
}
