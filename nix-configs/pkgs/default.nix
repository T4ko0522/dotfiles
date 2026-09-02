{
  nixosLoadingPlymouth,
  pkgs,
}: {
  chiffonCursor = import ./chiffon-cursor/package.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  codexbar = pkgs.callPackage ./codexbar/package.nix {};
  codexPetReimu = pkgs.callPackage ./codex-pets/reimu.nix {};
  librepods = pkgs.callPackage ./librepods/package.nix {};
  linuxWallpaperengineCapture = pkgs.callPackage ./linux-wallpaperengine/package.nix {};
  plymouthTheme = pkgs.callPackage ./plymouth-theme/package.nix {
    script = ../assets/plymouth/nixos-loading-logs.script;
    sourceTheme = nixosLoadingPlymouth.packages.${pkgs.stdenv.hostPlatform.system}.nixos-loading-default;
  };
  swaylockLongIdle = pkgs.callPackage ./swaylock-long-idle/package.nix {};
  swaynotificationcenterSlide = pkgs.callPackage ./swaynotificationcenter/package.nix {};
  vimdocJa = pkgs.callPackage ./vim-plugins/vimdoc-ja/package.nix {};
  vitePlus = pkgs.callPackage ./vite-plus/package.nix {};
  waycal = pkgs.callPackage ./waycal/package.nix {};
  winresizer = pkgs.callPackage ./vim-plugins/winresizer/package.nix {};
  wivrnNvenc =
    (pkgs.callPackage ./wivrn/package.nix {cudaSupport = true;}).overrideAttrs
    (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          driverLib=${pkgs.addDriverRunpath.driverLink}/lib
          for f in "$out"/bin/.wivrn-server-wrapped "$out"/lib/wivrn/*.so*; do
            if [ -f "$f" ] && patchelf --print-rpath "$f" >/dev/null 2>&1; then
              patchelf --add-rpath "$driverLib" "$f"
            fi
          done
        '';
    });
}
