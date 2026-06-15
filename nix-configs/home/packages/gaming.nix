{pkgs, ...}: {
  home.packages = with pkgs; [
    (prismlauncher.override {
      jdks = [
        jdk25
        jdk21
        jdk17
        jdk8
      ];
    })
    alcom
    osu-lazer-bin
    polychromatic
    protonup-qt
    vrcx
    wineWow64Packages.stable
    winetricks
  ];
}
