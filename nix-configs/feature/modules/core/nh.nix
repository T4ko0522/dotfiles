{dotfilesPath, ...}: {
  programs.nh = {
    enable = true;
    flake = dotfilesPath;
  };
}
