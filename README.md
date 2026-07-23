# Dotfiles

NixOS、NixOS-WSL、Windowsの環境を管理しているdotfiles.

## Nix

```text
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
          ▜███▙       ▜███▙  ▟███▛
           ▜███▙       ▜███▙▟███▛
            ▜███▙       ▜██████▛
     ▟█████████████████▙ ▜████▛     ▟▙
    ▟███████████████████▙ ▜███▙    ▟██▙
           ▄▄▄▄▖           ▜███▙  ▟███▛
          ▟███▛             ▜██▛ ▟███▛
         ▟███▛               ▜▛ ▟███▛
▟███████████▛                  ▟██████████▙
▜██████████▛                  ▟███████████▛
      ▟███▛ ▟▙               ▟███▛
     ▟███▛ ▟██▙             ▟███▛
    ▟███▛  ▜███▙           ▝▀▀▀▀
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛
           ▟██████▙         ▜███▙
          ▟███▛▜███▙         ▜███▙
         ▟███▛  ▜███▙         ▜███▙
         ▝▀▀▀    ▀▀▀▀▘         ▀▀▀▘
```

Inspired by [akazdayo/nix-configs](https://github.com/akazdayo/nix-configs), [moons-14/dotfiles](https://github.com/moons-14/dotfiles), [mozumasu/dotfiles](https://github.com/mozumasu/dotfiles).

## NixOS-WSL

NixOS-WSLの初期イメージ内でこのリポジトリをcloneし、次の構成を適用する。

```sh
sudo nixos-rebuild switch --flake .#wsl
```

WSL構成は`t4ko`ユーザー、Windows interop、CLI用Home Manager profileを有効にする。desktop packageとNeovim設定は含まない。

```sh
just wsl-check
```
