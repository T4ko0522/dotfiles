{pkgs, ...}: let
  swaynotificationcenterWithSlideDismiss = pkgs.swaynotificationcenter.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        substituteInPlace data/ui/notification.blp \
          --replace-fail "transition-type: crossfade;" "transition-type: slide_right;"
      '';
  });
in {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    gsimplecal
    networkmanagerapplet
    pamixer
    swaynotificationcenterWithSlideDismiss
    waybar
    wl-clipboard
    xwayland-satellite
    xdg-utils
  ];
}
