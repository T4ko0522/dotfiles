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

NixOSの再構築後にchezmoi profileを適用し、Home Managerの対象外へ移したdotfileも配置する。

```sh
just os-switch laptop
```

## NixOS-WSL

NixOS-WSLの初期イメージ内でこのリポジトリをcloneし、NixOS構成とchezmoiの`wsl` profileを適用する。

```sh
just wsl-switch
```

WSL構成は`t4ko`ユーザー、Windows interop、CLI用Home Manager profileを有効にする。desktop packageとNeovim設定は含まない。

```sh
just wsl-check
```
