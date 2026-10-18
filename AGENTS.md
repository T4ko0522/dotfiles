# AGENTS.md

このリポジトリで作業するエージェント向けのガイドです。実装前に構成と既存の責務分担を確認し、不要な抽象化や大きな再編は避けてください。

## コマンド

- Nix ファイルを整形: `nix run nixpkgs#alejandra -- .`
- Nix 構文チェック: `git ls-files '*.nix' | xargs -n1 nix-instantiate --parse --quiet >/dev/null`
- Nix 整形チェック: `nix run nixpkgs#alejandra -- --check .`
- キャッシュ設定の検証: `bash scripts/ci/check-binary-caches.sh`
- profile 契約の検証: `bash scripts/ci/check-profiles.sh`
- Nixvim の生成設定・plugin・keymap の確認: `bash scripts/ci/check-nixvim.sh`（Linux、Nixvim 変更時）

ホスト構成の build:

```sh
nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.desktop.config.system.build.toplevel
# macOS 上で実行
nix build --no-link .#darwinConfigurations.macmini.system
```

Justfile はありません。追加の Nix lint が必要な場合は `nix run nixpkgs#statix -- check .` を使います。既存の style warning が残っている場合は失敗することがあります。警告修正が目的でない変更では、無関係な大規模修正に広げないでください。

## CI

GitHub Actions は次の 3 workflow で実行します。

- `lint.yml`: PR・master push・手動実行で Nix 構文・整形、キャッシュ設定、profile 契約を検証します。PR・手動実行では laptop・desktop も build します。
- `publish-cache.yml`: master へのすべての push で laptop・desktop を build・署名・cache publish します。手動実行では `host` で片方を指定でき、空なら両方が対象です。
- `update-flake-lock.yml`: 毎朝 08:15 JST の予定で全 flake inputs を更新し、差分があれば GitHub App token で `flake.lock` を master へ直接署名付きコミットします。手動実行もできます。

共通の Nix 導入・キャッシュ設定は `.github/actions/setup-nix/action.yml` にあります。flake 更新用 App の設定は `docs/flake-updates.md` を参照してください。

## 構成

- `flake.nix`: flake inputs、Linux / Darwin のホスト構成、dev shell を定義します。
- `nix-configs/lib/`: Linux / Darwin の構成 builder と共有データを置きます。
- `nix-configs/hosts/`: `laptop/`・`desktop/`・`macmini/` の system / Home Manager 構成入口です。物理ホストの自動生成由来の hardware 設定は目的なしに整理しないでください。
- `nix-configs/linux/modules/`: NixOS の単一機能モジュールです。
- `nix-configs/linux/profiles/`: base、workstation、gaming など用途別の NixOS profile です。
- `nix-configs/darwin/`: macOS の system module / profile です。Homebrew の設定もここで管理します。
- `nix-configs/home/`: Home Manager 設定です。`profiles/common.nix` が両 OS 共通、`profiles/linux.nix` が Linux、`profiles/darwin.nix` が macOS の機能をまとめます。
- `nix-configs/home/modules/packages/`: Home Manager の package group です。
- `nix-configs/pkgs/`: ローカル package の定義・関連 source と、共通 / Linux 専用の package registry です。
- `corne/`: Corne キーボード関連の設定、keymap、生成スクリプトです。
- `docs/`: keybindings などのドキュメントです。

## Flake

Linux は `x86_64-linux`、macmini は `aarch64-darwin` 向けです。

- `nixosConfigurations.laptop`: laptop ホスト構成
- `nixosConfigurations.desktop`: desktop ホスト構成
- `nixosConfigurations.default`: `laptop` の alias
- `devShells.x86_64-linux.default`: QMK/Vial 作業用 shell
- `darwinConfigurations.macmini`: nix-darwin + Home Manager + nix-homebrew
- `devShells.aarch64-darwin.default`: dotfiles の整形・検証用 shell

Linux / Darwin の構成は `nix-configs/lib/mk-nixos.nix` と `mk-macos.nix` で組み立てます。macmini は単一構成で管理し、適用後の desktop / server モードは `mac-mode desktop`・`mac-mode server`・`mac-mode status` で操作します。

各 builder の `specialArgs` と Home Manager の `extraSpecialArgs` を確認し、`dotfilesPath`・`username`・`homeDirectory`・`editor`・`localPackages` など必要な既存引数を使ってください。`keyboardLayout` は Linux 向けです。

## ファイル配置ルール

- `nix-configs/linux/modules/` は複数構成で共有する単一機能の NixOS 設定を置きます。module から profile を import しません。
- `nix-configs/linux/profiles/` は用途別の機能 bundle です。module の実装を持たず、原則として imports で構成します。
- `nix-configs/darwin/modules/` と `nix-configs/darwin/profiles/` も同じ責務分担にします。
- `nix-configs/home/modules/` は単一の Home Manager 機能、`nix-configs/home/profiles/` はその bundle を置きます。
- 書き戻し不要な静的設定は `nix-configs/home/modules/**/files/` に置き、Home Manager から Nix store 経由で配置します。
- アプリが書き戻す実体は、担当する Home Manager module の `files/` に置き、`dotfilesPath` を使う `mkOutOfStoreSymlink` で管理します。
- `nix-configs/home/modules/packages/*.nix` は目的別の `home.packages` group です。CLI、development、gaming など既存分類に合わせてください。
- 共通のローカル package は `nix-configs/pkgs/default.nix`、Linux 専用は `nix-configs/pkgs/linux.nix` に登録し、module から `localPackages` で参照します。Linux / Darwin / Home module 内で package を定義しません。
- キャッシュの共有データは `nix-configs/lib/binary-caches.nix` に置きます。flake のリテラル値と CI setup action の設定も一致させ、`check-binary-caches.sh` で確認します。
- 新しい module は参照元の `imports`、package は対応する registry に追加してください。flake 評価で使う新規ファイルは Git に track されている必要があります（評価前は `git add -N <path>` でも可）。

## Agent Skills

- [`T4ko0522/skills`](https://github.com/T4ko0522/skills) を唯一の直接依存として、選択済み skills と Home Manager module を取り込みます。
- skill の追加・更新や外部 source の選択は `T4ko0522/skills` 側で管理します。このリポジトリの `nix-configs/home/modules/agents/agent-skills.nix` は配置先と既存ディレクトリの移行処理だけを設定します。

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

作業中は変更対象の構文・評価・必要な実環境の確認に絞ります。CI 相当の包括的な確認は、予定した変更を終え、ユーザーがコミットを指示した時にまとめて行います。

コミット前は「コマンド」の構文・整形・キャッシュ設定・profile 契約のチェックと、`lint.yml` の laptop / desktop build を確認します。Darwin 固有の変更では macOS 上の build・動作確認を行い、Linux の評価結果とは区別して報告してください。

package 追加や NixOS module 変更では、必要に応じて以下も確認します。

```sh
nix eval .#nixosConfigurations.default.config.home-manager.users.t4ko.home.packages --apply 'xs: builtins.length xs'
nix eval .#nixosConfigurations.default.config.boot.kernelPackages.kernel.version --raw
```
