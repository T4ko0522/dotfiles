# Windows / NixOS dotfiles 設計の深掘り（選択肢）

`windows-nixos-dotfiles-design.md`の検討過程を残した資料。現在の決定事項は同文書を正とし、この文書内の`home/` source root、旧`dot_config/`、`setup_windows.ps1`、Maximal構成、両OS共通nvimなどのパスと案は移行前の記録であり、現行実装を表さない。

## 現状から見えた制約・論点

調査で判明した、設計を縛る既存事実。

- NixOS は `nix-configs/home/modules/xdg/files.nix` で **二層戦略**を取っている。
  - out-of-store symlink（`mkOutOfStoreSymlink`, xdg.nix:11）: 実行時に書き戻る／頻繁に変わるもの。lazygit `state.yml`、nvim `lazy-lock.json`、codex `config.toml`、zsh `rc`、fcitx5 `config`、`.gitconfig`、claude `skills`。**rebuild 不要・repo を直接 live-edit** が狙い。
  - in-store readonly: 静的なもの。starship、fastfetch、vim、wezterm、yazi。変更に `just os-switch` が要る。
- Claude `settings.json` は **shared base + OS 固有 hooks のマージ生成**。NixOS は `home.activation`（xdg.nix:100-108）、Windows は `setup_windows.ps1`（144-162）で**同じことを二重実装**している。
- niri / waybar / swaync は **Nix がテンプレート生成**している。per-host monitor（laptop/desktop で出力構成が違う）、Catppuccin palette、keyboard layout(`jp`/`jp106`) を Nix 値で KDL/JSON/CSS に埋め込む（niri.nix:67-186 ほか）。これらは Linux 専用かつ Nix ネイティブ。
- Windows は `setup_windows.ps1` が 41 エントリのリンク表 + symlink→hardlink→copy フォールバック（75-104）を手書きしている。
- flake は `laptop` / `desktop` / `wsl` の 3 ホスト。hostname 判定あり。
- CI は alejandra / nix-instantiate / statix と実ホスト構成の build。taplo は未統合。

**含意**: chezmoi が素直に置き換えられるのは「Claude settings のマージ二重実装」と「Windows のリンク表」。逆に **niri 系の Nix テンプレートは chezmoi に移せない**（移すと per-host/palette/keyboard のデータ源を失う）。そして既存が大事にしている **live-edit（out-of-store）の性質を chezmoi の既定モデルが壊しうる**——ここが最大の論点。

## 中心的な分岐: chezmoi の「適用モデル」

chezmoi の既定は **source → target の一方向コピー**（managed copy）。現状の out-of-store symlink とは思想が真逆。ここをどう設計するかで全体像が決まる。3 つのモードを**ファイル特性で使い分ける**のが軸。

### モード A: managed copy（chezmoi 既定）

source の実体を target へコピー。target を直接編集すると drift し、`chezmoi re-add` / `chezmoi merge` で戻す。

- 向き: 静的設定（starship, fastfetch, vim, wezterm, yazi）。
- 利点: chezmoi の最も素直な使い方。`chezmoi diff` がそのまま効く。
- 欠点: 実行時に書き戻るファイルでは常時 drift。live-edit と相性が悪い。

### モード B: symlink stub → plain working tree（out-of-store 相当）

chezmoi source には `symlink_` エントリ（中身 = link 先 path、`.tmpl` で `{{ .chezmoi.workingTree }}/...` を生成可能）だけを置き、**実体は repo 内の plain なツリー**に置いて symlink を張る。

- 向き: 書き戻り系・churn 系（lazygit state, nvim lazy-lock, codex config, zsh, fcitx5, gitconfig）。
- 利点: **現状の out-of-store symlink / Windows junction を、両 OS 一つの定義で再現**。rebuild 不要・repo 直接編集を維持。Windows の junction 手書きも消える。
- 欠点: chezmoi の「source が唯一の真実」イデオロギーからは外れる。実体ツリーは chezmoi の naming 変換外に置く必要がある。

### モード C: template 生成（`.tmpl`）

複数入力をマージ／OS 分岐して target を生成。

- 向き: Claude `settings.json`（base + OS hooks マージ）、OS で内容が変わる設定。
- 利点: Nix activation と PowerShell の**二重実装を 1 ファイルに集約**。
- 欠点: 生成物なので live-edit は上書きされる（現状の Claude settings も同じ挙動なので問題なし）。

### 推奨: 3 分類で割り当て

現状の in-store / out-of-store / activation の 3 分類が、そのまま A / B / C に対応する。これを踏襲するのが移行コスト・思想ともに最小。

| 現状 | 対象例 | chezmoi モード |
|------|--------|----------------|
| in-store readonly | starship, fastfetch, vim, wezterm, yazi | A: managed copy |
| out-of-store symlink | lazygit, nvim, codex, zsh, fcitx5, gitconfig | B: symlink stub |
| activation 生成 | claude settings.json | C: template |

## chezmoi と Nix の責務境界（所有マトリクス）

**不変条件: 1 つの target path は chezmoi か Nix のどちらか一方だけが所有する**（衝突回避。後述）。

| 対象 | OS | 所有 | 方式 |
|------|----|------|------|
| nvim / lazygit / codex / zsh / gitconfig | both | chezmoi | B symlink |
| starship / fastfetch / vim / wezterm / yazi | both | chezmoi | A copy |
| claude settings.json | both | chezmoi | C template |
| claude skills/agents | both | chezmoi | B symlink |
| fcitx5 config | linux | chezmoi | B symlink |
| **niri / waybar / swaync** | linux | **Nix** | Nix template（据え置き） |
| package / service / systemd / system | linux | **Nix** | 据え置き |
| powershell / cava / YASB | windows | chezmoi | A/B |

niri 系を Nix に残すのは、per-host monitor・palette・keyboard というデータを Nix が握っているため。これらを chezmoi に移すと、そのデータを `.chezmoidata` 等へ再実装する羽目になる（次節）。Linux 専用なので Windows との共有不要＝ chezmoi に出す動機も薄い。

## 共有データの扱い（palette / keyboard / per-host）

Nix 側には `specialArgs`（keyboardLayout, dotfilesDir）、per-host monitors、Catppuccin palette がある。chezmoi 側には `.chezmoidata` + `.chezmoi.hostname`。**同じ値を両 OS で使いたくなったとき**（例: Catppuccin を Windows の wezterm でも統一）にデータ源が二つになる。

- 案 1: **分離（疎結合）**。Nix の desktop データは Nix 内に閉じ、chezmoi 側 cross-platform 設定は `.chezmoidata` に独自定義。重複は許容。実装が単純で初手向き。
- 案 2: **単一ソース**。`palette.toml` / `theme.toml` を 1 つ置き、Nix は `builtins.fromTOML`、chezmoi は `.chezmoidata.toml`（または `include | fromToml`）で**両方が同じファイルを読む**。色やキーボードを一元化できる。やや構築コスト。

初期は案 1、テーマ統一の要求が出たら案 2 へ昇格、が現実的。

## Claude settings を 1 テンプレートへ集約（具体）

現状の Nix activation + PowerShell の二重実装を、chezmoi template 1 枚へ。

```gotmpl
{{/* home/dot_claude/settings.json.tmpl */}}
{{- $base := include "dot_config/shared/claude/settings.json" | fromJson -}}
{{- $os := eq .chezmoi.os "windows" | ternary "windows" "nixos" -}}
{{- $hooks := include (printf ".config/%s/claude/settings.hooks.json" $os) | fromJson -}}
{{ mergeOverwrite $base $hooks | toPrettyJson }}
```

これで `xdg.nix:100-108` の activation と `setup_windows.ps1:144-162` の PowerShell マージが両方不要になる。最も分かりやすい chezmoi の利得。

ただし注意（Codex 指摘）:

- `include` は **source directory 相対**。`.chezmoiroot=home/` にするなら、上記 `dot_config/shared/...` は `home/` 配下に置かれている必要がある。レイアウト確定前に最小 PoC で解決を確認すること。
- `mergeOverwrite` は **deep merge だが deep copy ではなく右側優先、配列は連結しない**。現 PS は `hooks` を丸ごと差し替え、Nix は `recursiveUpdate`。テンプレート化前に **JSON fixture テスト**で挙動を固定し、両 OS で一致させること。

## 書き戻し系の symlink 設計（Windows junction も統一）

モード B を両 OS 共通の `symlink_` で表現すると、現状バラバラな 2 実装が 1 つになる。

```gotmpl
{{/* ~/.config/nvim を repo 作業ツリーへ向ける symlink */}}
{{/* source: home/dot_config/symlink_nvim.tmpl, 中身 = link 先 */}}
{{ .chezmoi.workingTree }}/live/nvim
```

- Linux: `mkOutOfStoreSymlink`（xdg.nix の out-of-store 群）を chezmoi symlink へ移譲。
- Windows: junction（setup_windows.ps1）を chezmoi symlink へ移譲。chezmoi は Windows で symlink 権限が無ければ挙動が変わるため、**ディレクトリは junction 相当が要るか**を要検証（未解決点）。
- 実体は `live/`（仮）= chezmoi 変換外の plain ツリーに置く。現状の `dot_config/shared` の役割をここが引き継ぐ。

## Home Manager と chezmoi の衝突回避（correctness）

最重要の正しさ要件。HM の `home.file` / `xdg.configFile` は target を HM 管理として張り、activation 時に**未管理の実体があると backup/error する**。chezmoi が同じ path を触ると壊れる。

- 不変条件: **全 target を {HM, chezmoi} のどちらか一方が排他所有**。
- 移行手順は必ず「**HM から該当エントリを削除 → その後 chezmoi に所有させる**」の順。逆だと衝突。
- `~/.config` ディレクトリ自体は HM が `xdg.configFile` で**エントリ単位**管理するので、chezmoi が別エントリ（niri 以外）を持つのは可。ただし**同一 path の二重管理は不可**。
- CI で「HM が張る path 集合」と「chezmoi が apply する path 集合」が**素**であることを検査するチェックを足すと安全（未実装の提案）。

## secrets / 権限

codex `config.toml` は `-rw-------`(600) でセッションキーを含む可能性があり、現状 repo に実体がある（out-of-store symlink 元）。chezmoi なら:

- `private_` 接頭辞で 0600 を宣言的に再現。
- 真に秘匿すべき値は `encrypted_`（age/gpg）で commit 内容を暗号化、という昇格パスがある。

初期は `private_` で権限再現、秘匿要件が固まったら `encrypted_` 検討。

## run_ scripts でできること

chezmoi の `run_onchange_` / `run_once_` で、現状の補助処理を宣言的に。

- PowerShell profile の `conf.d` インライン展開（`optim_pwsh_profile.ps1`）→ `run_onchange_` 化。
- 初回 bootstrap の machine 設定収集 → `.chezmoi.toml.tmpl` の `promptString` 等。
- apply 後フック（cache 再生成など）。

## アーキテクチャ全体案

### 案 1: Maximal chezmoi（推奨・ユーザー方針に合致）

cross-platform な編集対象 dotfiles を**全て chezmoi が所有**（nvim, starship, lazygit, claude, codex, zsh, wezterm, yazi, vim, fastfetch, gitconfig）。Nix は **niri/waybar/swaync/fcitx5(任意) + package/service/system のみ**。xdg.nix の dotfile-link 部分は大幅削除。

- 利点: 「nixos 最低限」を最も満たす。Windows と定義を最大共有。
- 欠点: 移行が最も大きい。HM 削除と chezmoi 化を慎重に段階実施。

### 案 2: Hybrid（クラス分け）

真に cross-platform なものだけ chezmoi、Nix テンプレートの恩恵が大きいものは Linux で Nix 維持。

- 利点: 移行リスク低、各々の強みを活かす。
- 欠点: 「どっちが持つか」の判断が増える。nixos 最低限度は中程度。

### 案 3: Windows-primary

chezmoi は主に Windows、NixOS は現状の HM 維持。

- 利点: NixOS をほぼ触らない＝最小リスク。
- 欠点: **「nixos 最低限に」というユーザー方針に反する**。共有も限定的。不採用寄り。

→ ユーザー方針（nixos 最低限）から **案 1 を本線**、移行中の安全弁として一部 **案 2** を併用、が妥当。

## 代替ツール（なぜ chezmoi）

- GNU Stow / dotbot: symlink は張れるが OS 分岐・テンプレート・マージが弱い。Claude settings マージを別実装する羽目。
- yadm: bare git + alternates。chezmoi に近いが template/data 機構は chezmoi が上。
- bare git: 最小だが OS 差分・生成を全部自前。
- home-manager を Windows でも: WSL 前提になり native Windows を外す。非現実的。

→ OS 分岐 + template + マージ + 一貫した diff/verify を 1 ツールで賄える点で chezmoi が適合。

## Codex 独立レビュー所見

別系統（Codex / gpt-5.5）に公平な批判的精査を依頼した結果。多くが妥当で、設計に反映すべき。

1. **「全面採用」は強すぎる。本線は Hybrid（案 2）**。chezmoi が明確に勝つのは Windows の 41 エントリ表と Claude settings の二重実装の解消。一方 NixOS の out-of-store/in-store 二層は成熟しており、捨てるほどの負債ではない、との評価。→ 本メモの「案 1 Maximal 推奨」は再考の余地あり（後述の決定事項）。
2. **`symlink_` で Windows junction まで置換する前提は危険**。chezmoi の `symlink_` は symbolic link を作る機能で junction 互換を保証しない。現 PS の「dir=junction / file=symlink→hardlink→copy」フォールバックは Windows 権限問題を踏んだ知見。**Windows ディレクトリは `symlink_` 前提にせず `run_onchange_` で junction を明示作成**すべき。開発者モード/権限の現実も要検証。
3. **HM↔chezmoi の排他所有は「不変条件の明記」だけでは不足**。HM 生成 path と chezmoi 管理 path の**交差を CI で検出する仕組みが必須**。activation 順序では根本解決しない（同一 path を両者が持った時点で負け）。
4. **`mergeOverwrite` は deep merge だが deep copy ではない・右側優先・配列は連結されない**。現 PS は `hooks` を丸ごと差し替え、Nix は `recursiveUpdate`。**テンプレート化前に JSON fixture テストで挙動を固定**し、両 OS で一致させること。
5. **`.chezmoiroot=home/` と `include` パスが矛盾している**（実バグ）。chezmoi の `include` は **source directory 相対**。source root を `home/` にすると、本メモの Claude 例が使う `dot_config/shared/...` という include パスはズレる。**最小 PoC で確認してから**実装すること。
6. **見落とし代替**: 「Windows だけ chezmoi、NixOS は現状 HM 維持」が技術的に最小リスク。ユーザー方針（nixos 最低限）とはズレるが、選択肢として明記すべき。次点は「Claude settings と Windows 共有対象だけ chezmoi、live-edit 系（nvim/lazygit/zsh/fcitx5）は当面 HM out-of-store のまま」。
7. **後戻り不能点**: `dot_config/shared` を `live/` へ大移動 → HM リンク削除、の局面。ここで Windows junction 代替が不完全だと両 OS の足場が同時に崩れる。**先に「Windows symlink_/run_ の PoC」「Claude settings の fixture テスト」「HM/chezmoi path 交差チェック」を用意してから移行**。

Codex の自己推奨: **Hybrid**。chezmoi は Windows bootstrap / Windows 配置 / Claude settings 生成 / 真に cross-platform な静的 dotfiles から始め、NixOS の二層戦略と niri/waybar/swaync は維持。Windows dir は junction を `run_onchange_` で明示。

参考: chezmoi target-types / include, Sprig mergeOverwrite の仕様（symlink は symbolic link、include は source 相対、mergeOverwrite は deep merge 非 deep copy）。

### レビューを受けた方針補正

- 推奨アーキテクチャは **案 1 Maximal を「最終形」、案 2 Hybrid を「移行の現実的な本線」** と二段構えにする。ユーザー方針（nixos 最低限）は最終形で満たしつつ、Hybrid から漸進する。
- Windows ディレクトリ配置は `symlink_` 前提を撤回し、**junction は `run_onchange_`** を既定とする。
- 移行の**先行タスク**として PoC 3 点（Windows link、Claude fixture、path 交差 CI）を必須化する。

## リスク・未解決点（次に決めること）

**先行 PoC（移行着手前に必須・Codex 指摘）**

- P1. **Windows link PoC**: `symlink_` のディレクトリ挙動と、junction を `run_onchange_` で作る方式を実機検証（権限/開発者モード含む）。
- P2. **Claude settings fixture テスト**: `mergeOverwrite` の出力が Nix `recursiveUpdate` / 現 PS と一致するか JSON fixture で固定。
- P3. **HM↔chezmoi path 交差 CI**: 両者の target path 集合が素であることを検査するチェックを用意。
- P4. **`.chezmoiroot` × `include` PoC**: source root を `home/` にした時の include 解決を最小再現で確認。

**決定事項**

1. **最終形（案 1 Maximal）と移行本線（案 2 Hybrid）の二段構えで進めるか**、いきなり Maximal か。
2. Codex 推奨どおり **Hybrid 起点**（Windows + Claude settings + cross-platform 静的から）にするか、ユーザー方針優先で Maximal を急ぐか。
3. **symlink stub の実体ツリー名**（`live/`?）と `dot_config/shared` からの移設手順。
4. **共有データを案 1（分離）で始めるか案 2（単一 toml）にするか**。
5. niri/waybar/swaync を **完全に Nix 据え置き**でよいか（Windows と見た目を揃える要求が無いか）。
6. codex config を `private_` で足りるか `encrypted_` まで要るか。
7. 「Windows だけ chezmoi / NixOS は HM 維持」という**最小リスク代替**を採らない理由を明文化するか。
