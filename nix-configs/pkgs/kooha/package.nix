{stdenv}: let
  # Pin Kooha 2.3.0 and its build dependencies independently of system updates.
  source = builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "21a67dc470149f337cecafbe965d8d252a390518";
    narHash = "sha256-ugpsyk3NM2s87vXfUiIIiibbJ4Pp0JPS5p/3mfs+q+c=";
  };
  pinnedPkgs = import source.outPath {
    inherit (stdenv.hostPlatform) system;
    config = {};
    overlays = [];
  };
in
  pinnedPkgs.kooha.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./support-pipewire-dmabuf.patch];
  })
