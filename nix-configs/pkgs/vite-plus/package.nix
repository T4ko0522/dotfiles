{
  autoPatchelfHook,
  fetchurl,
  glibc,
  lib,
  stdenv,
}: let
  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-f46IAFyVK6+WkW50qQHNPJ6f4Wtoj9WEdOjsOhfTpkE=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-2m07OPIdNyIhrg/jsI4dTRePIkPHlHmim+FzLXZm0eo=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
  stdenv.mkDerivation rec {
    pname = "vite-plus";
    version = "0.2.6";

    src = fetchurl {
      url = "https://github.com/voidzero-dev/vite-plus/releases/download/v${version}/vp-${source.target}.tar.gz";
      inherit (source) hash;
    };

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [glibc stdenv.cc.cc.lib];
    dontUnpack = true;

    installPhase = ''
      tar -xzf $src
      install -Dm755 vp $out/bin/vp
    '';

    meta = {
      description = "Unified toolchain for web development";
      homepage = "https://viteplus.dev/";
      license = lib.licenses.mit;
      mainProgram = "vp";
      platforms = builtins.attrNames sources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
