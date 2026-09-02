{
  config,
  lib,
  ...
}: {
  programs.naniTranslateLinux.enable = true;
  t4ko.niri.popup.autoClose.nani.appIdPattern = "^nani$";

  xdg = {
    mimeApps.defaultApplications."x-scheme-handler/naniapp" = "nani.desktop";

    configFile."niri/nani-translate.kdl".text = ''
      binds {
        Ctrl+J repeat=false { spawn "${config.t4ko.niri.popup.package}/bin/niri-popupctl" "open-primary-selection" "naniapp://translate?source="; }
        Mod+Ctrl+J repeat=false { spawn "${config.t4ko.niri.popup.package}/bin/niri-popupctl" "open-uri" "naniapp://translate"; }
      }

      window-rule {
        match app-id="(?i)^nani$"
        open-floating true
        open-focused true
        default-column-width { fixed 1200; }
        default-window-height { fixed 850; }
        default-floating-position x=0 y=120 relative-to="top"
        opacity 0.9
      }
    '';

    configFile."niri/config.kdl".text = lib.mkAfter ''
      include "${config.xdg.configHome}/niri/nani-translate.kdl"
    '';
  };
}
