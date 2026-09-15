{
  mkRayCastExtension,
  mkVicinaeExtension,
  pkgs,
}: let
  ghqPackageLock = builtins.fromJSON (builtins.readFile ./ghq-package-lock.json);
  ghqOverride = name: let
    dependency = ghqPackageLock.packages."node_modules/${name}";
  in
    toString (pkgs.fetchurl {
      url = dependency.resolved;
      hash = dependency.integrity;
    });
  ghqNpmDeps = pkgs.importNpmLock {
    package =
      ghqPackageLock.packages.""
      // {
        overrides = {
          brace-expansion = ghqOverride "brace-expansion";
          "js-yaml@4" = ghqOverride "js-yaml";
        };
      };
    packageLock = ghqPackageLock;
  };
  raycastRev = "995b2d0b0e105a6562e2664d0bf6903f65b616c4";
  vicinaeRev = "ee117bc64f341ed71b4a27e311f343b12a75f43d";
  vicinaeExtensionsSrc = pkgs.fetchFromGitHub {
    owner = "vicinaehq";
    repo = "extensions";
    rev = vicinaeRev;
    hash = "sha256-Os614eK4hYC8l9cECt2zBiQbrdv+9q2AyrliHfiEf5A=";
  };
  mkOfficialExtension = name:
    mkVicinaeExtension {
      inherit name;
      pname = "vicinae-extension-${name}";
      version = "0-unstable-2026-09-08";
      src = "${vicinaeExtensionsSrc}/extensions/${name}";
      npmFlags = ["--legacy-peer-deps"];
      postPatch = ''
        substituteInPlace tsconfig.json --replace-warn "../../" "${vicinaeExtensionsSrc}/"
      '';
    };
in {
  chromiumBookmarks = mkOfficialExtension "chromium-bookmarks";
  firefox = mkOfficialExtension "firefox";
  ghq = mkRayCastExtension {
    name = "ghq";
    rev = raycastRev;
    hash = "sha256-B+v5Pf1yBdVF1aiphtqqTIJnOj2BcT2BXYLzWMETn0o=";
    npmDeps = ghqNpmDeps;
    patches = [./ghq-linux.patch];
  };
  processManager = mkOfficialExtension "process-manager";

  qrcodeGenerator = mkRayCastExtension {
    name = "qrcode-generator";
    rev = raycastRev;
    hash = "sha256-iQa+Cq9UivVeGDl2HdIopDeFNd6awZtCXfeJgKva1bw=";
  };

  raySo = mkRayCastExtension {
    name = "ray-so";
    rev = raycastRev;
    hash = "sha256-9NPO3pOfFM/G6FTdhlCwZW6wF1pqoUkiivdtHPf1+oc=";
  };
}
