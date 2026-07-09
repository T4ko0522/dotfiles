{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_7_1;
}
