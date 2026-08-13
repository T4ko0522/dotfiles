{ dotfilesPath, ... }: {
  programs.nh = {
    enable = true;
    flake = dotfilesPath;
    clean = {
      enable = true;
      dates = "daily";
      extraArgs = "--keep 5";
    };
  };
}
