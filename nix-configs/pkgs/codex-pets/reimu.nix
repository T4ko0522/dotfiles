{
  fetchurl,
  runCommand,
}: let
  version = "1786933449527";

  petJson = fetchurl {
    url = "https://codex-pets.net/assets/pets/v/${version}/reimu/pet.json";
    hash = "sha256-vm4p+ge4MyVK3RJj6/gkAP9CMOwSDTjp2HhMoX396HI=";
  };

  spritesheet = fetchurl {
    url = "https://codex-pets.net/assets/pets/v/${version}/reimu/spritesheet.webp";
    hash = "sha256-X78V/9xrsSsZxhV0Sq2i+d1dbDjuik2oH3qbOYqDMBw=";
  };
in
  runCommand "codex-pet-reimu-${version}" {} ''
    install -Dm444 ${petJson} "$out/pet.json"
    install -Dm444 ${spritesheet} "$out/spritesheet.webp"
  ''
