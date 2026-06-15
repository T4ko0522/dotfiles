{
  dotfilesDir,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      # Steam and gaming
      "steam"
      "steam-unwrapped"
      "steam-original"
      "steam-run"
      "proton-ge-bin"
      # Browsers
      "brave"
      "google-chrome"
      # Media
      "spotify"
      "osu-lazer-bin"
      # Infrastructure
      "terraform"
      # LLM agents
      "claude-code"
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
    substituters = [
      "https://vicinae.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  programs.nh = {
    enable = true;
    flake = dotfilesDir;
  };
}
