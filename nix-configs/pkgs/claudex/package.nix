{
  applyPatches,
  cacert,
  lib,
  rustPlatform,
  src,
}:
rustPlatform.buildRustPackage {
  pname = "claudex";
  version = "0.2.4";

  src = applyPatches {
    inherit src;
    name = "claudex-source";
    patches = [
      ./reasoning-effort.patch
      ./oauth-keyring-fallback.patch
    ];
  };

  cargoHash = "sha256-10Mmiofblkrc7DVw6y2U+odeue0Mv1UuLNHy4ClV91o=";

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  meta = {
    description = "Multi-instance Claude Code manager with an AI-provider translation proxy";
    homepage = "https://claudex.space";
    license = lib.licenses.mit;
    mainProgram = "claudex";
    platforms = lib.platforms.linux;
  };
}
