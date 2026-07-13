{pkgs, ...}: {
  programs.codexDesktopLinux = {
    enable = true;
    cliPackage = pkgs.codex;
  };
}
