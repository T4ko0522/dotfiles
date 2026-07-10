{pkgs, ...}: let
  swaynotificationcenterWithSlideDismiss = pkgs.swaynotificationcenter.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [./patches/swaync-control-center-slide.patch];
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        substituteInPlace data/ui/notification.blp \
          --replace-fail "transition-type: crossfade;" "transition-type: slide_right;"
      '';
  });

  waycal = pkgs.rustPlatform.buildRustPackage rec {
    pname = "waycal";
    version = "0.2.0";

    src = pkgs.fetchFromGitHub {
      owner = "forrestknight";
      repo = "waycal";
      rev = "237640a09242408e767d68e2080b0f011fecc8e3";
      hash = "sha256-h/+L1cAVdamfUGcz5wFGgLNcXCq/O3/LSQJ4Ap8kS2E=";
    };

    cargoHash = "sha256-zOOG8vF0d3+X85O6bu0Y5XKNZSjcufKMHXQmZ54jCXw=";
    nativeBuildInputs = [pkgs.pkg-config];
    buildInputs = [
      pkgs.gtk4
      pkgs.gtk4-layer-shell
    ];

    postPatch = ''
      substituteInPlace src/main.rs \
        --replace-fail '#1a2125' '#1e1e2e' \
        --replace-fail '#8FBC8F' '#cba6f7' \
        --replace-fail '#c9d1d9' '#cdd6f4' \
        --replace-fail '#6a7a71' '#7f849c' \
        --replace-fail 'rgba(26, 33, 37, 0.96)' 'rgba(30, 30, 46, 0.96)' \
        --replace-fail 'rgba(143, 188, 143, 0.18)' 'rgba(203, 166, 247, 0.18)'
    '';

    meta = {
      description = "Tiny GTK4 calendar popup for Waybar";
      homepage = "https://www.waycal.dev";
      license = pkgs.lib.licenses.mit;
      mainProgram = "waycal";
    };
  };
in {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    libnotify
    networkmanagerapplet
    pamixer
    swaynotificationcenterWithSlideDismiss
    waycal
    waybar
    wl-clipboard
    xwayland-satellite
    xdg-utils
  ];
}
