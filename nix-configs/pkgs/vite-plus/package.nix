{
  autoPatchelfHook,
  fetchurl,
  glibc,
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "vite-plus";
  version = "latest";

  src = fetchurl {
    url = "https://github.com/voidzero-dev/vite-plus/releases/latest/download/vp-x86_64-unknown-linux-gnu.tar.gz";
    # Update this hash when the latest Vite+ release changes.
    hash = "sha256-Pwu2w1AAtNFJWf9zRkTdjFsMfi5rP2ia7yw+UguBzUU=";
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
