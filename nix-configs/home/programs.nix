{...}: {
  imports = [./programs-cli.nix];

  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    withPython3 = true;
    extraPython3Packages = ps: [ps.pynvim];
  };
}
