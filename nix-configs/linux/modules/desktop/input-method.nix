{
  keyboardLayout,
  pkgs,
  ...
}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-material-color
        qt6Packages.fcitx5-qt
      ];
      settings.inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = keyboardLayout.fcitxLayout;
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-jp";
          Layout = keyboardLayout.fcitxLayout;
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
          Layout = keyboardLayout.fcitxLayout;
        };
        GroupOrder."0" = "Default";
      };
    };
  };

  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
