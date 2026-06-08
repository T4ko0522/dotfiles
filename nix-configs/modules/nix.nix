{
  dotfilesDir,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # Steam and gaming
    "steam"
    "steam-original"
    "steam-run"
    "proton-ge-bin"
    # Browsers
    "brave"
    "google-chrome"
    # Media
    "spotify"
    "osu-lazer-bin"
    # AI / LLM tools
    "claude-code"
    "codex"
    "opencode"
    # Infrastructure
    "terraform"
    # NVIDIA proprietary drivers
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = ["https://vicinae.cachix.org"];
    trusted-public-keys = ["vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="];
  };

  programs.nh = {
    enable = true;
    flake = dotfilesDir;
  };
}
