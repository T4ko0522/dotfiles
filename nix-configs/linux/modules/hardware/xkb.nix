{pkgs, ...}: {
  services.xserver.xkb.extraLayouts.corne-jp = {
    description = "Japanese layout for Corne with US grave/tilde key";
    languages = ["jpn"];
    symbolsFile = pkgs.writeText "corne-jp.xkb" ''
      default partial alphanumeric_keys
      xkb_symbols "basic" {
          include "jp"

          replace key <HZTG> { [ grave, asciitilde ] };
      };
    '';
  };
}
