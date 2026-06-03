{pkgs, ...}: let
  chiffonCursor = pkgs.callPackage ../../cursors/chiffon.nix {};
in {
  home.pointerCursor = {
    package = chiffonCursor;
    name = "Chiffon";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
}
