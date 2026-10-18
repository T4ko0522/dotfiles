# Dotfiles

NixOS の laptop / desktop と macOS の macmini を Home Manager とともに管理する dotfiles.

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

NixOS の設定とユーザー環境は Home Manager とともに適用されます。リポジトリのルートで実行します。desktop には `-H desktop` を指定します。

```sh
nh os switch . -H laptop
```

## macOS / Mac mini

Apple Silicon の `macmini` を nix-darwin + Home Manager で管理します。
CLI は Nix、GUI アプリは Homebrew cask を使い、Homebrew 本体と taps も Nix で宣言します。
クローン先は `~/dotfiles` です。Nix 導入済みの macmini 上で build・適用します。

```sh
cd ~/dotfiles
export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes"
nix build .#darwinConfigurations.macmini.system
sudo ./result/sw/bin/darwin-rebuild switch --flake .#macmini --option accept-flake-config true
```

適用後は `mac-mode desktop` / `mac-mode server` で管理対象の常駐アプリを切り替え、`mac-mode status` で状態を確認できます。

インフラ構築には `terraform` / `tofu`、`ansible`、`openstack` を利用できます。
Docker が必要なときは `colima start --runtime docker` で起動し、`docker info` や `docker compose` を使います。Linux VM の管理には `limactl` も利用できます。
この設定の適用では VM の作成・起動は行いません。OpenStack 本体は、必要に応じて後から Linux VM に構築します。

## Nix の整形・検証

Nix ファイルの整形は `alejandra .` を使います。macmini では `nix develop` で整形・lint 用のツールを利用できます。

```sh
git ls-files -z '*.nix' | xargs -0 -n1 nix-instantiate --parse --quiet
alejandra --check .
statix check .
deadnix --fail .
bash scripts/ci/check-binary-caches.sh
```

Linux の profile 検証と両ホストの build:

```sh
bash scripts/ci/check-profiles.sh
nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.desktop.config.system.build.toplevel
```

macmini の build のみを行う場合:

```sh
nix build --no-link .#darwinConfigurations.macmini.system
```

Neovim 固有の検証は、必要に応じて `bash scripts/ci/check-nixvim.sh` を実行します。
