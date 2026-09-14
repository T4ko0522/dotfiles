{
  config,
  dotfilesPath,
  ...
}: {
  xdg.configFile."fcitx5/config".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/fcitx5/files/config";
}
