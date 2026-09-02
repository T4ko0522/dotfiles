# Dotfiles

NixOS と NixOS-WSL の環境を Home Manager とともに管理する dotfiles.

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

NixOS の設定とユーザー環境は Home Manager とともに適用されます。

```sh
just os-switch laptop
```

## NixOS-WSL

NixOS-WSL は `t4ko` ユーザー、Windows interop、CLI 用 Home Manager profile を有効にします。desktop package と Neovim 設定は含みません。

```sh
just wsl-switch
just wsl-check
```
