{config, ...}: let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in {
  xdg.configFile = {
    "fcitx5/config".source = link "mutable/fcitx5/config";
  };
}
