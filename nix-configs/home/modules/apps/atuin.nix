{...}: {
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"
      "--disable-ai"
    ];
    settings = {
      inline_height = 0;
      enter_accept = false;
    };
  };
}
