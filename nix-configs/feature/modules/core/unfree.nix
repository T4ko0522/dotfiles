{lib, ...}: {
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
      "zoom"
      # VRChat avatar tooling
      "unityhub"
      "corefonts"
      # Infrastructure
      "terraform"
      # LLM agents
      "claude-code"
      "codex-desktop"
      # NVIDIA proprietary drivers
      "nvidia-x11"
      "nvidia-settings"
      "nvidia-persistenced"
    ];
}
