# Dotfiles

NixOS、NixOS-WSL、macOS の環境を Home Manager とともに管理する dotfiles.

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

## macOS / Mac mini

Apple Silicon の `macmini` を nix-darwin + Home Manager で管理します。
CLI は Nix、GUI アプリは Homebrew cask を使い、Homebrew 本体と taps も Nix で宣言します。
クローン先は `~/dotfiles` です。初回導入と管理対象は [macmini の手順](docs/macmini.md) を参照してください。

```sh
export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes"
nix develop
just mac-check
just mac-switch
```
