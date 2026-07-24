{
  autoPatchelfHook,
  fetchurl,
  glibc,
  lib,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "vite-plus";
  version = "0.2.6";

  src = fetchurl {
    url = "https://github.com/voidzero-dev/vite-plus/releases/download/v${version}/vp-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-f46IAFyVK6+WkW50qQHNPJ6f4Wtoj9WEdOjsOhfTpkE=";
  };

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [glibc stdenv.cc.cc.lib];
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
    platforms = lib.platforms.linux;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
}
