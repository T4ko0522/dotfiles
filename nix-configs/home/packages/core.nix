{pkgs, ...}: {
  imports = [./core-cli.nix];

  home.packages = with pkgs; [
    ghostty
    wezterm
    zed-editor
  ];
}
