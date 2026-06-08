{
  programs = {
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
