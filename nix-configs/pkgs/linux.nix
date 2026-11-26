{
  inirPackage,
  pkgs,
}: {
  chiffonCursor = import ./chiffon-cursor/package.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  codexbar = pkgs.callPackage ./codexbar/package.nix {};
  inir = pkgs.callPackage ./inir/package.nix {inherit inirPackage;};
  kooha = pkgs.callPackage ./kooha/package.nix {};
  librepods = pkgs.callPackage ./librepods/package.nix {};
  linuxWallpaperengineCapture = pkgs.callPackage ./linux-wallpaperengine/package.nix {};
  pensoDock = pkgs.callPackage ./penso-dock/package.nix {};
  swaynotificationcenterSlide = pkgs.callPackage ./swaynotificationcenter/package.nix {};
  waycal = pkgs.callPackage ./waycal/package.nix {};
  xwaylandSatellite = pkgs.xwayland-satellite;
  wivrnNvenc = pkgs.callPackage ./wivrn/package.nix {cudaSupport = true;};
}
