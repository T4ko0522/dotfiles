{
  nixosLoadingPlymouth,
  pkgs,
}: {
  chiffonCursor = import ./chiffon-cursor/package.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  codexbar = pkgs.callPackage ./codexbar/package.nix {};
  kooha = pkgs.callPackage ./kooha/package.nix {};
  librepods = pkgs.callPackage ./librepods/package.nix {};
  linuxWallpaperengineCapture = pkgs.callPackage ./linux-wallpaperengine/package.nix {};
  plymouthTheme = pkgs.callPackage ./plymouth-theme/package.nix {
    script = ../assets/plymouth/nixos-loading-logs.script;
    sourceTheme = nixosLoadingPlymouth.packages.${pkgs.stdenv.hostPlatform.system}.nixos-loading-default;
  };
  swaynotificationcenterSlide = pkgs.callPackage ./swaynotificationcenter/package.nix {};
  waycal = pkgs.callPackage ./waycal/package.nix {};
  xwaylandSatellite = pkgs.xwayland-satellite;
  wivrnNvenc = pkgs.callPackage ./wivrn/package.nix {cudaSupport = true;};
}
