{pkgs, ...}: {
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    plemoljp-nf
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = ["PlemolJP Console NF" "Noto Sans Mono CJK JP"];
    sansSerif = ["Noto Sans CJK JP" "Noto Sans"];
    serif = ["Noto Serif CJK JP" "Noto Serif"];
    emoji = ["Noto Color Emoji"];
  };
}
