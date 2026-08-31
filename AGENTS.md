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

`specialArgs`とHome Managerの`extraSpecialArgs`には`dotfilesDir`、`keyboardLayout`、`username`、`homeDirectory`などが渡されています。これらが必要なmoduleでは、ハードコードを増やさず既存の引数を使ってください。

## ファイル配置ルール

- `nix-configs/feature/modules/` は複数構成で共有する単一機能の NixOS 設定を置きます。module から profile を import しません。
- `nix-configs/feature/profiles/` は用途別の機能 bundle です。module の実装を持たず、原則として imports で構成します。
- `nix-configs/home/modules/` は単一の Home Manager 機能、`nix-configs/home/profiles/` はその bundle を置きます。
- `nix-configs/home/modules/packages/*.nix` は目的別の `home.packages` group です。CLI、development、gaming など既存分類に合わせてください。
- `nix-configs/pkgs/` は derivation のみを置き、feature/Home module 内で package を定義しません。
- 新しい Nix ファイルは、参照元の `imports` に必ず追加してください。flake 評価で使う新規ファイルは Git に track されている必要があります。

## Claude Code の skill 管理 (apm)

- skill の source は `mutable/shared/apm/packages/<category>/.apm/skills/<name>/` に置き、apm (Agent Package Manager) で管理します。カテゴリ (`agent-llm`・`docs`・`git-ops` など) は local apm package で、root の `apm.yml` が `dependencies.apm: [./packages/<category>]` として参照します。
- 新しいカテゴリを追加する場合は `packages/<category>/apm.yml` を作成し、root の `apm.yml` の `dependencies.apm` へ追記してください。apm と Claude Code はどちらも skill のネスト配置に非対応のため、deploy 先はフラット (`.claude/skills/<name>/`) になります。skill 名はカテゴリを跨いで一意にしてください。
- `apm install` (home-manager activation で自動実行、手動は `just skills-sync`) が各 package と外部依存を `mutable/shared/apm/.claude/skills/` へ deploy します。
- 外部 skill も root の `apm.yml` の `dependencies.apm` に追加できます。現在は `mizchi/skills` の一部 (nix-setup・justfile・apm-usage・conventional-changelog・gh-fix-ci・cloudflare/deploy・workers-otel-utels) を取り込んでいます。HEAD が動くため必ず `#<commit-sha>` でピンし、更新時は SHA を差し替えて `apm install` で lockfile を再生成してください。
- 生成物 (`.claude/skills/`・`apm_modules/`) は gitignore されています。`~/.claude/skills` は生成物への symlink なので、skill の追加・編集は必ず source 側で行ってください。
- `apm.lock.yaml` は外部依存のバージョン固定のため **追跡** しています (gitignore しない)。`dependencies.apm` を変更したら `apm install` を実行し、更新後の lockfile も併せてコミットしてください。

## スタイル

- Nix の整形は `alejandra` を使います。
- Nix ファイルは既存の `{pkgs, ...}: { ... }` 形式に合わせます。
- package list は原則 `with pkgs; [ ... ]` の既存スタイルに合わせます。
- 新しいファイル名は小文字の kebab-case を使います。
- 設定の移動や refactor では、挙動変更と構造変更を混ぜないでください。

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
