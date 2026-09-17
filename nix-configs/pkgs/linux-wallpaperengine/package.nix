{
  dbus,
  fetchFromGitHub,
  freetype,
  linux-wallpaperengine,
}:
linux-wallpaperengine.overrideAttrs (old: {
  version = "0-unstable-2026-07-08";

  src = fetchFromGitHub {
    owner = "Almamu";
    repo = "linux-wallpaperengine";
    rev = "b016d7d1fdcf4e5fd2f9c9fa420a8aaa07fee02d";
    hash = "sha256-ExWAYdSFW5plPuS3/jxTPMXIly6zVb5GojE3e37imZM=";
    fetchSubmodules = true;
  };

  buildInputs =
    (old.buildInputs or [])
    ++ [
      dbus
      freetype
    ];

  patches =
    (old.patches or [])
    ++ [
      ./capture-before-fullscreen-pause.patch
      ./puppet-warp-skeletal-animation.patch
      ./preserve-authored-image-size.patch
    ];
})
