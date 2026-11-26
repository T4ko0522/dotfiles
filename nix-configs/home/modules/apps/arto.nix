{
  arto,
  pkgs,
  ...
}: {
  home.packages = [arto.packages.${pkgs.stdenv.hostPlatform.system}.default];
}
