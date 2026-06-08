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

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    plemoljp-nf
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "PlemolJP Console NF"
      "Noto Sans Mono CJK JP"
    ];
    sansSerif = [
      "Noto Sans CJK JP"
      "Noto Sans"
    ];
    serif = [
      "Noto Serif CJK JP"
      "Noto Serif"
    ];
    emoji = ["Noto Color Emoji"];
  };

  services = {
    xserver.enable = false;

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
          user = "greeter";
        };
      };
    };

    printing.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    configPackages = [pkgs.niri];
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  hardware.graphics.enable = true;
}
