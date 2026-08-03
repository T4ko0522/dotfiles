{
  config,
  lib,
  pkgs,
  ...
}: let
  translateSelection = pkgs.writeShellScript "nani-translate-selection" ''
    source="$(${pkgs.wl-clipboard}/bin/wl-paste --primary --no-newline)"
    [ -n "$source" ] || exit 0

    source_uri="$(printf '%s' "$source" | ${pkgs.jq}/bin/jq -sRr @uri)"
    ${pkgs.xdg-utils}/bin/xdg-open "naniapp://translate?source=$source_uri"
  '';
in {
  programs.naniTranslateLinux.enable = true;

  xdg.mimeApps.defaultApplications."x-scheme-handler/naniapp" = "nani.desktop";

  xdg.configFile."niri/nani-translate.kdl".text = ''
    binds {
      Ctrl+J repeat=false { spawn "${translateSelection}"; }
      Mod+Ctrl+J repeat=false { spawn "${pkgs.xdg-utils}/bin/xdg-open" "naniapp://translate"; }
    }
  '';

  xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
    include "${config.xdg.configHome}/niri/nani-translate.kdl"
  '';
}
