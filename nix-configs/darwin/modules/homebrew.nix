{
  config,
  homebrew-core,
  homebrew-cask,
  lib,
  username,
  ...
}: {
  # Run after nix-homebrew sets up the prefix (order 500), before bundle (1000).
  # Homebrew's completion sandbox can write here once the parent exists.
  system.activationScripts.homebrew.text = lib.mkOrder 750 ''
    /usr/bin/install -d -o ${lib.escapeShellArg username} -g admin -m 0755 /opt/homebrew/share/pwsh/completions
  '';

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = username;
    autoMigrate = true;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    global = {
      autoUpdate = false;
      brewfile = true;
    };
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # Preserve packages during the initial migration. See docs/macmini.md.
      cleanup = "none";
    };
    masApps."RunCat Neo" = 6757801838;
    casks = [
      "brave-browser"
      "chatgpt"
      "discord"
      "font-cascadia-mono"
      "font-line-seed-jp"
      "font-plemol-jp-nf"
      "github"
      "google-chrome"
      "karabiner-elements"
      "omniwm"
      "proton-pass"
      "raycast"
      "rustdesk"
      "spotify"
      "wezterm"
      "zed"
    ];
  };
}
