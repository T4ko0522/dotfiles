# AGENTS.md

このリポジトリで作業するエージェント向けのガイドです。実装前に構成と既存の責務分担を確認し、不要な抽象化や大きな再編は避けてください。

## コマンド

- Nix ファイルを整形: `just fmt`
- Nix 構文チェック: `just syntax`
- Nix lint: `just lint`
- laptop の NixOS 構成を build: `just build`
- CI 相当の確認: `just ci`

`just lint` は `statix check .` を実行します。既存の style warning が残っている場合は失敗することがあります。警告修正が目的でない変更では、無関係な大規模修正に広げないでください。

## CI

GitHub Actions は `.github/workflows/ci.yml` から各 workflow を呼び出し、以下を実行します。

- `git ls-files '*.nix' | xargs -r -n1 nix-instantiate --parse --quiet`
- `alejandra --check .`
- laptop・desktop・wsl の NixOS 構成を build

ローカルでは `just ci` がこれに近い確認です。

## 構成

- `flake.nix`: flake inputs と `nixosConfigurations` を定義します。
- `nix-configs/hosts/`: ホスト別の構成入口です。`laptop/`・`desktop/`・`wsl/`があります。物理ホストの自動生成由来のhardware設定は目的なしに整理しないでください。
- `nix-configs/feature/modules/`: NixOS の単一機能モジュールです。
- `nix-configs/feature/profiles/`: base、workstation、gaming など用途別の NixOS profile です。
- `nix-configs/home/`: Home Manager 設定です。
- `nix-configs/home/modules/packages/`: Home Manager の package group です。
- `corne/`: Corne キーボード関連の設定、keymap、生成スクリプトです。
- `docs/`: keybindings などのドキュメントです。

## Flake

現在の flake は `x86_64-linux` 向けです。

- `nixosConfigurations.laptop`: laptop ホスト構成
- `nixosConfigurations.desktop`: desktop ホスト構成
- `nixosConfigurations.wsl`: NixOS-WSL 用の CLI 構成
- `nixosConfigurations.default`: `laptop` の alias
- `devShells.x86_64-linux.default`: QMK/Vial 作業用 shell

`specialArgs`とHome Managerの`extraSpecialArgs`には`dotfilesPath`、`keyboardLayout`、`username`、`homeDirectory`などが渡されています。これらが必要なmoduleでは、ハードコードを増やさず既存の引数を使ってください。

## ファイル配置ルール

- `nix-configs/feature/modules/` は複数構成で共有する単一機能の NixOS 設定を置きます。module から profile を import しません。
- `nix-configs/feature/profiles/` は用途別の機能 bundle です。module の実装を持たず、原則として imports で構成します。
- `nix-configs/home/modules/` は単一の Home Manager 機能、`nix-configs/home/profiles/` はその bundle を置きます。
- 書き戻し不要な静的設定は `nix-configs/home/modules/**/files/` に置き、Home Manager から Nix store 経由で配置します。
- アプリが書き戻す実体は、担当する Home Manager module の `files/` に置き、`dotfilesPath` を使う `mkOutOfStoreSymlink` で管理します。
- `nix-configs/home/modules/packages/*.nix` は目的別の `home.packages` group です。CLI、development、gaming など既存分類に合わせてください。
- `nix-configs/pkgs/` は derivation のみを置き、feature/Home module 内で package を定義しません。
- 新しい Nix ファイルは、参照元の `imports` に必ず追加してください。flake 評価で使う新規ファイルは Git に track されている必要があります。

## Agent Skills

- `Kyure-A/agent-skills-nix` が skills を Home Manager で各 agent target へ配置します。
- 自作 skill は `nix-configs/home/modules/agents/files/skills/<name>/` にフラットに置きます。外部 skill の source と選択は `agents/agent-skills.nix` で管理します。

## スタイル

- Nix の整形は `alejandra` を使います。
- Nix ファイルは既存の `{pkgs, ...}: { ... }` 形式に合わせます。
- package list は原則 `with pkgs; [ ... ]` の既存スタイルに合わせます。
- 新しいファイル名は小文字の kebab-case を使います。
- 設定の移動や refactor では、挙動変更と構造変更を混ぜないでください。

## 開発スタイル

- この dotfiles リポジトリでは TDD を必須としません。変更内容に応じて既存の Nix 構文・評価・build や実環境で確認してください。

## 変更時の注意

- ユーザーの未 commit 変更を勝手に戻さないでください。
- この dotfiles リポジトリでは、新しいテストファイルやテスト用 fixture を追加しないでください。変更の確認には既存の CI コマンド、Nix の評価・build、実環境での動作確認を使ってください。
- `flake.lock` の `"version": 7` は lock file 形式のバージョンです。Linux kernel version ではありません。
- Home Manager package を追加する場合は、system package と user package のどちらに置くべきか確認してください。個人用 GUI/CLI は通常 `nix-configs/home/modules/packages/` 側です。
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
nix eval .#nixosConfigurations.default.config.home-manager.users.t4ko.home.packages --apply 'xs: builtins.length xs'
nix eval .#nixosConfigurations.default.config.boot.kernelPackages.kernel.version --raw
just wsl-check
```
