{
  config,
  dotfilesPath,
  ...
}: let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in {
  xdg.configFile = {
    "fcitx5/config".source = link "nix-configs/home/modules/xdg/files/fcitx5/config";
  };
}
