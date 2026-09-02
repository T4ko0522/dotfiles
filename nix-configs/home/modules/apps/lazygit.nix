{
  config,
  dotfilesPath,
  ...
}: {
  xdg.configFile."lazygit".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/lazygit/files";
}
