{config, ...}: {
  programs = {
    neovim = {
      enable = true;
      sideloadInitLua = true;
      withPython3 = true;
      extraPython3Packages = ps: [ps.pynvim];
    };

    go = {
      enable = true;
      env.GOPATH = "${config.home.homeDirectory}/go";
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
      defaultOptions = [
        "--height 40%"
        "--reverse"
        "--border"
      ];
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
