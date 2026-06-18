# Windows / NixOS dotfiles 設計

## 目的

Windows と NixOS の両方で同じ dotfiles を運用する。OS 差分は chezmoi の template と ignore で吸収し、「どちらか片方だけ設定が増える」「リンク先がズレる」「存在しない設定を参照する」といった不整合を `chezmoi diff` / `chezmoi verify` で機械的に検出できる状態にする。

最終形では、dotfiles の配置を chezmoi が単一の applier として担い、NixOS の Home Manager は package / service / desktop profile など Nix でしか表現できない領域に専念する。

## 採用方針

- dotfiles の適用は chezmoi に一本化する（Windows / NixOS 共通）
- 独自の契約 TOML + PowerShell executor は採用しない（chezmoi が肩代わりする）
- OS 差分は物理ディレクトリ分割ではなく chezmoi の template (`.tmpl`) と `.chezmoiignore` で表現する
- machine 固有値は `.chezmoidata` / `.chezmoi.toml.tmpl` に集約する
- Python は採用しない
- NixOS では Home Manager の dotfiles リンクを撤退し、最低限（package / service / profile）に絞る
- repository をそのまま chezmoi の source directory として使う
- **最終形は Maximal（NixOS 撤退）だが、移行は Hybrid 起点で漸進する**（Windows + Claude settings + cross-platform 静的 → live-edit 系 → Maximal）

## 責務分担

### chezmoi（配置）

repo を chezmoi の source とし、`chezmoi apply` で home 配下へ配置する。OS 差分は template と ignore で解決する。Windows / NixOS の両方でこの applier を共有する。

### NixOS（最低限）

Home Manager は以下だけを管理する。

- package
- service / systemd user unit
- desktop profile（niri など Nix 生成が必要なもの）
- system 設定

dotfiles のシンボリックリンク定義は Home Manager から削除し、chezmoi に委譲する。niri のように Nix で生成する必要がある設定は引き続き Nix が持ち、chezmoi の管理対象外にする。

### Windows

`scripts/setup_windows.ps1` は chezmoi の bootstrap（install + `chezmoi init --apply`）だけを担う。リンク対象の個別列挙は廃止する。

## ソース構成（chezmoi source）

`.chezmoiroot` で `home/` を source root に指定し、chezmoi の naming convention で配置する。

```text
dotfiles/
  .chezmoiroot            # "home" を指す
  home/
    .chezmoi.toml.tmpl    # chezmoi config 生成（data / OS 判定）
    .chezmoidata.toml     # 静的データ（editor 名など）
    .chezmoiignore        # OS ごとの除外
    dot_config/
      nvim/...
      starship.toml
      ...
    ...
  nix-configs/            # NixOS: package / service / profile のみ
  scripts/
    setup_windows.ps1     # chezmoi bootstrap のみ
  docs/
```

naming convention:

- `dot_foo` → `~/.foo`
- `private_foo` → permission 0600
- `executable_foo` → 実行ビット付与
- `foo.tmpl` → Go template として評価
- `symlink_foo` → symlink（ファイル内容が link 先 path）
- `run_onchange_foo` → 内容変化時に実行する script

## OS 差分の扱い

旧設計の `shared` / `windows` / `nixos` 物理分割は廃止し、chezmoi の仕組みへ置き換える。

- 共有設定: そのまま source に置く（両 OS に適用される）
- 内容が OS で異なる: `foo.tmpl` 内で `{{ if eq .chezmoi.os "windows" }}` 分岐
- 片方だけに置く: `.chezmoiignore` で対象外の OS を除外

```text
# .chezmoiignore
{{ if ne .chezmoi.os "windows" }}
AppData/**
{{ end }}
{{ if ne .chezmoi.os "linux" }}
dot_config/niri/**
{{ end }}
```

## 配置先が OS で違う場合

nvim のように、Linux では `~/.config/nvim`、Windows では `%LOCALAPPDATA%\nvim` と配置先が異なるものは次のように扱う。

- 正準の内容は `dot_config/nvim` に一度だけ置く
- Windows 向けは `AppData/Local/nvim` を `symlink_`、もしくは `run_onchange_` の junction 作成で `dot_config/nvim` の実体へ向ける
- `.chezmoiignore` で OS ごとに不要な側を除外する

これで内容の二重管理を避けつつ、OS ごとの配置先差分を吸収する。

## 実行時に書き戻される設定

Claude / Codex のように tool が runtime で書き戻す設定は、chezmoi の managed copy にすると drift する。これらは次のいずれかで扱う。

- `symlink_` で repo 作業ツリーの実体へ link する（旧 `outOfStoreSymlink` 相当）
- `modify_` script で既存内容を尊重してマージする

推奨は symlink。tool の書き込みが直接 repo に届き、`chezmoi apply` と競合しない。

## machine データ

`.chezmoi.toml.tmpl` で OS と machine を判定し、`.chezmoidata.toml` の静的値と合わせて template に渡す。

```toml
# .chezmoidata.toml
editor = "nvim"
```

```toml
# .chezmoi.toml.tmpl
[data]
hostname = {{ .chezmoi.hostname | quote }}
os = {{ .chezmoi.os | quote }}
```

template 側ではこれらを `{{ .editor }}` / `{{ .hostname }}` として参照する。

## 整合性チェック

独自の PowerShell checker は廃止し、chezmoi 標準を使う。

- `chezmoi doctor`: 環境の健全性
- `chezmoi verify`: 適用済み状態と source の一致
- `chezmoi diff`: 差分（CI で空であることを確認）
- `chezmoi execute-template`: template が両 OS で評価できるか

## CI

`just ci` の例:

```sh
chezmoi doctor
chezmoi diff --source home              # diff が無いこと
just check-ownership                    # HM target と chezmoi target が素であること
just check-claude-settings             # 生成 settings.json が fixture と一致すること
alejandra --check .
nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel
```

- `check-ownership`: Home Manager が生成する target path 集合と chezmoi が管理する target path 集合の**交差が空**であることを検査する（二重所有の事故防止）。不変条件の明記だけでは不足なので CI で機械検出する。
- `check-claude-settings`: `mergeOverwrite` で生成した `settings.json` が、固定した JSON fixture（＝旧 Nix `recursiveUpdate` / 旧 PowerShell マージと一致する期待値）と一致することを検査する。配列・深いキーの扱いの差異を回帰検出する。

Windows 側の差分は GitHub Actions の windows runner で `chezmoi apply --dry-run` を回して検証する。

## bootstrap

両 OS 共通:

```sh
chezmoi init --apply <repo-url>
```

- Windows: `setup_windows.ps1` が chezmoi を winget で導入し、`chezmoi init --apply` を呼ぶ
- NixOS: chezmoi を package に追加し、初回のみ `chezmoi init --apply`。以降は `chezmoi apply`

## NixOS 連携の方針

Home Manager から dotfiles リンクを撤去する。`chezmoi apply` を Nix の activation に組み込むことも可能だが、Nix eval と chezmoi を密結合させないため、`chezmoi apply` は明示実行（手動 or systemd user oneshot）にとどめる。

niri など Nix 生成が必須の設定は Nix 側に残し、chezmoi の管理対象外（`.chezmoiignore`）にする。

## tools.toml（package 整合）

dotfiles とは別に package の整合を取りたい場合、chezmoi の `.chezmoidata` や `run_onchange_` script で扱える。Windows は winget、NixOS は Nix が package を持つため、capability 単位の管理は将来拡張とする。最初は dotfiles の chezmoi 化を優先する。

## 段階移行（Hybrid 起点 → Maximal 最終形）

最終形は案 1 Maximal（NixOS は dotfiles 配置から撤退）。ただし一気に寄せず、リスクの低い領域から段階的に chezmoi へ移す。各 Phase は exit 条件を満たしてから次へ進む。設計の選択肢・トレードオフは `windows-nixos-dotfiles-design-options.md` を参照。

### Phase 0: 先行 PoC（移行前に必須）

実体は動かさず、危険な前提を実機で潰す。

- P1. Windows link PoC: `symlink_` のディレクトリ挙動を検証し、junction は `run_onchange_` で明示作成する方式を確立（権限/開発者モード込み）。
- P2. Claude settings fixture: `mergeOverwrite` 出力が旧 Nix `recursiveUpdate` / 旧 PowerShell マージと一致するか JSON fixture で固定。
- P3. HM↔chezmoi path 交差 CI: 両者の target path 集合が素であることを検査する `check-ownership` を用意。
- P4. `.chezmoiroot` × `include` PoC: source root を `home/` にした時の `include` 解決を最小再現で確認。

exit: P1〜P4 がすべて green。Windows ディレクトリ配置と Claude settings 生成の方式が確定。

### Phase 1: Hybrid 起点

chezmoi が明確に勝つ領域だけ先に移す。NixOS の live-edit 二層はまだ触らない。

- Windows: `setup_windows.ps1` を chezmoi bootstrap のみへ簡略化。Windows 専用配置（komorebi / yasb / whkd / cava / powershell / mise / ccwin）を chezmoi へ。
- Claude `settings.json`: 両 OS とも chezmoi template（モード C）へ集約。`xdg.nix` の activation と PS マージを撤去。
- cross-platform 静的（starship / fastfetch / vim / wezterm / yazi）: chezmoi managed copy（モード A）へ。NixOS の in-store エントリは HM から削除（churn しないので低リスク）。

exit: 上記 path が HM から消え chezmoi 所有へ移行。`check-ownership` green。両 OS で `chezmoi diff` が空。

### Phase 2: live-edit 系の移譲

書き戻し・churn 系を chezmoi の symlink stub（モード B）へ。P1 の junction 方式が前提。

- nvim / lazygit / zsh / fcitx5 / codex / gitconfig / claude skills を `symlink_`（実体は plain ツリー）へ。
- NixOS の out-of-store symlink（`mkOutOfStoreSymlink`）を chezmoi 由来へ置換。live-edit・rebuild 不要の性質は維持。
- codex config は `private_`（必要なら `encrypted_`）で権限/秘匿を再現。

exit: out-of-store 群が chezmoi 所有へ移行。両 OS で live-edit が rebuild なしに効くことを確認。

### Phase 3: Maximal 化（NixOS 最低限）

- `xdg.nix` の dotfile-link 定義を削除し、HM は package / service / systemd / system のみへ縮小。
- niri / waybar / swaync は **Nix 据え置き**（per-host monitor / palette / keyboard を Nix が握るため）。`.chezmoiignore` で chezmoi 対象外に。
- 旧 contract / 暫定 checker 案を破棄。

exit: NixOS の dotfiles 配置が chezmoi 一本化（Nix 生成必須の Linux desktop を除く）。

## ファイル別 所有 / モード対応

| 対象 | OS | 現状 | 移行先所有 | モード | Phase |
|------|----|------|-----------|--------|-------|
| claude settings.json | both | activation/PS マージ | chezmoi | C template | 1 |
| starship / fastfetch / vim / wezterm / yazi | both | HM in-store | chezmoi | A copy | 1 |
| komorebi / yasb / whkd / cava / powershell / mise / ccwin | windows | PS リンク表 | chezmoi | A/B | 1 |
| nvim / lazygit / gitconfig / claude skills | both | HM out-of-store | chezmoi | B symlink | 2 |
| zsh rc / fcitx5 config | linux | HM out-of-store | chezmoi | B symlink | 2 |
| codex config.toml | both | HM out-of-store | chezmoi | B symlink + private_ | 2 |
| niri / waybar / swaync | linux | Nix template | **Nix 据え置き** | — | — |
| package / service / system | linux | Nix | **Nix 据え置き** | — | — |

## 判断

chezmoi を採用することで、Windows / NixOS の dotfiles 配置を単一の applier に統一できる。独自契約 + PowerShell executor を実装・保守する必要がなくなり、OS 差分は chezmoi の template と ignore に集約される。NixOS は最終的に Nix にしかできない領域（package / service / profile + Nix 生成必須の Linux desktop）に専念し、dotfiles 配置からは撤退する。

ただし独立レビュー（Codex）の指摘どおり、既存 NixOS の out-of-store/in-store 二層戦略は成熟しており、一気に捨てるのはリスクが高い。よって **Maximal を最終形に据えつつ、Hybrid 起点で段階移行**する。先行 PoC（Windows link / Claude fixture / path 交差 CI / chezmoiroot×include）で危険な前提を潰してから着手する。

## 設計の深掘り

取りうる設計とトレードオフ（適用モデルの 3 分岐、Nix との責務境界、HM との衝突回避、共有データの扱いなど）は `windows-nixos-dotfiles-design-options.md` に分離して整理する。
