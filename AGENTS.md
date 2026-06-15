# AGENTS.md

このリポジトリで作業するエージェント向けのガイドです。実装前に構成と既存の責務分担を確認し、不要な抽象化や大きな再編は避けてください。

## コマンド

- 設定を適用: `just os-switch`
- Nix ファイルを整形: `just fmt`
- Nix 構文チェック: `just syntax`
- Nix lint: `just lint`
- NixOS 構成を build: `just build`
- CI 相当の確認: `just ci`

`just lint` は `statix check .` を実行します。既存の style warning が残っている場合は失敗することがあります。警告修正が目的でない変更では、無関係な大規模修正に広げないでください。

## CI

GitHub Actions は `.github/workflows/checks.yml` で以下を実行します。

- `git ls-files '*.nix' | xargs -r -n1 nix-instantiate --parse --quiet`
- `alejandra --check .`
- `nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel`

ローカルでは `just ci` がこれに近い確認です。

## 構成

- `flake.nix`: flake inputs と `nixosConfigurations` を定義します。
- `nix-configs/configuration.nix`: 通常の NixOS 構成の入口です。
- `nix-configs/configuration-ci.nix`: CI build 用の最小構成です。
- `nix-configs/hardware-configuration.nix`: ハードウェア設定です。自動生成由来の内容なので、目的なしに整理しないでください。
- `nix-configs/modules/`: NixOS 共通基盤モジュールです。
- `nix-configs/profiles/`: desktop、gaming、nvidia など用途別の NixOS profile です。
- `nix-configs/home/`: Home Manager 設定です。
- `nix-configs/home/packages/`: Home Manager の package group です。
- `corne/`: Corne キーボード関連の設定、keymap、生成スクリプトです。
- `docs/`: keybindings などのドキュメントです。

## Flake

現在の flake は `x86_64-linux` 向けです。

- `nixosConfigurations.nixos`: 通常構成
- `nixosConfigurations.default`: `nixos` の alias
- `nixosConfigurations.nixos-ci`: CI 用構成
- `devShells.x86_64-linux.default`: QMK/Vial 作業用 shell

`specialArgs` と Home Manager の `extraSpecialArgs` には `dotfilesDir` と `keyboardLayout` が渡されています。これらが必要な module では、ハードコードを増やさず既存の引数を使ってください。

## ファイル配置ルール

- `nix-configs/modules/` は複数構成で共有する NixOS 基盤設定を置きます。
- `nix-configs/modules/default.nix` は modules の入口です。基本的に child module の import に留めます。
- `nix-configs/modules/*.nix` は 1 ファイル 1 責務を保ちます。例: `kernel.nix` は kernel、`locale.nix` は locale、`qmk.nix` は udev/QMK。
- `nix-configs/profiles/` は用途別の機能 bundle です。desktop/gaming/nvidia など、常に全構成へ入れるべきでない設定を置きます。
- `nix-configs/home/packages/*.nix` は目的別の `home.packages` group です。CLI、development、gaming など既存分類に合わせてください。
- 新しい Nix ファイルは、参照元の `imports` に必ず追加してください。flake 評価で使う新規ファイルは Git に track されている必要があります。

## スタイル

- Nix の整形は `alejandra` を使います。
- Nix ファイルは既存の `{pkgs, ...}: { ... }` 形式に合わせます。
- package list は原則 `with pkgs; [ ... ]` の既存スタイルに合わせます。
- 新しいファイル名は小文字の kebab-case を使います。
- 設定の移動や refactor では、挙動変更と構造変更を混ぜないでください。

## 変更時の注意

- ユーザーの未 commit 変更を勝手に戻さないでください。
- `flake.lock` の `"version": 7` は lock file 形式のバージョンです。Linux kernel version ではありません。
- Linux kernel は `nix-configs/modules/kernel.nix` で指定します。
- Home Manager package を追加する場合は、system package と user package のどちらに置くべきか確認してください。個人用 GUI/CLI は通常 `nix-configs/home/packages/` 側です。
- `dogdns` のように nixpkgs で削除済みの package は、評価エラーの案内に従って代替 package を使ってください。
- secrets や token を tracked file に追加しないでください。

## 検証の目安

小さな Nix 変更では最低限以下を確認します。

```sh
just syntax
just ci
```

package 追加や NixOS module 変更では、必要に応じて以下も確認します。

```sh
nix eval .#nixosConfigurations.nixos.config.home-manager.users.t4ko.home.packages --apply 'xs: builtins.length xs'
nix eval .#nixosConfigurations.nixos.config.boot.kernelPackages.kernel.version --raw
```
