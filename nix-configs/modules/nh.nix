{dotfilesDir, ...}: {
  programs.nh = {
    enable = true;
    flake = dotfilesDir;
  };
}
