# Windows / NixOS dotfiles 設計

## 目的

Windows と NixOS の両方で同じ dotfiles を運用しつつ、どちらか片方だけに設定が増える、リンク先がズレる、存在しない設定を参照する、といった不整合を機械的に検出できる状態にする。

最終形では、ファイル配置の意図を 1 つの契約ファイルに集約し、Windows / NixOS それぞれの適用処理はその契約から導出する。

## 採用方針

- chezmoi は採用しない
- Python は採用しない
- 契約ファイルは TOML にする
- NixOS 側は `builtins.fromTOML` で契約を直接読む
- Windows 側は PowerShell で適用する
- TOML の検証や変換が必要な場合は、Python ではなく PowerShell と `taplo` などの CLI を使う
- Nix と Windows setup に同じリンク一覧を手書きしない

## 責務分担

### 契約

`contracts/dotfiles.toml` を source of truth にする。

ここには、どの source を、どの OS で、どの target へ、どの方式で配置するかを書く。

### 実体

- `.config/shared/`: Windows と NixOS の両方で使う設定
- `.config/windows/`: Windows 専用の設定
- `.config/nixos/`: NixOS 専用の設定

### Windows

`scripts/setup_windows.ps1` は契約に従って Windows の home 配下へリンク・生成を行う executor とする。

将来的には、リンク対象の一覧をスクリプト内に直接書かない。

### NixOS

Home Manager は `contracts/dotfiles.toml` から `xdg.configFile` / `home.file` を導出する adapter とする。

NixOS 側の package、service、desktop profile は引き続き `nix-configs/` が管理する。dotfiles のリンク一覧は Nix の手書きから撤退する。

## ディレクトリ構成

```text
dotfiles/
  contracts/
    dotfiles.toml
    tools.toml
  .config/
    shared/
    windows/
    nixos/
  scripts/
    setup_windows.ps1
    check_contracts.ps1
    export_contracts.ps1
  nix-configs/
    home/
      dotfiles-contract.nix
```

`tools.toml` は package / tool の整合性を扱うための将来拡張とする。最初は `dotfiles.toml` だけでよい。

## dotfiles.toml

基本形:

```toml
[[files]]
id = "nvim"
source = ".config/shared/nvim"
kind = "directory"
scope = "shared"

[files.targets.windows]
base = "localAppData"
path = "nvim"
mode = "junction"

[files.targets.nixos]
base = "xdgConfig"
path = "nvim"
mode = "outOfStoreSymlink"
```

ファイルの例:

```toml
[[files]]
id = "starship"
source = ".config/shared/starship.toml"
kind = "file"
scope = "shared"

[files.targets.windows]
base = "home"
path = ".config/starship.toml"
mode = "symlinkOrHardlink"

[files.targets.nixos]
base = "xdgConfig"
path = "starship.toml"
mode = "outOfStoreSymlink"
```

生成ファイルの例:

```toml
[[files]]
id = "claude-settings-windows"
kind = "generated"
scope = "windows"
generator = "jsonMerge"
inputs = [
  ".config/shared/claude/settings.json",
  ".config/windows/claude/settings.hooks.json",
]

[files.targets.windows]
base = "home"
path = ".claude/settings.json"
mode = "writeFile"
```

## フィールド

- `id`: 契約内で一意な識別子
- `source`: 配置元。`kind = "generated"` では省略可能
- `kind`: `file` / `directory` / `generated`
- `scope`: `shared` / `windows` / `nixos`
- `targets.windows`: Windows の配置先
- `targets.nixos`: NixOS の配置先
- `base`: target path の基準
- `path`: base からの相対 path
- `mode`: 配置方式
- `generator`: 生成方式
- `inputs`: 生成に使う入力ファイル

## base

Windows:

- `home`: `%USERPROFILE%`
- `localAppData`: `%LOCALAPPDATA%`
- `roamingAppData`: `%APPDATA%`
- `documents`: `%USERPROFILE%\Documents`

NixOS:

- `home`: `$HOME`
- `xdgConfig`: `$XDG_CONFIG_HOME`
- `xdgData`: `$XDG_DATA_HOME`
- `xdgState`: `$XDG_STATE_HOME`

## mode

Windows:

- `junction`: ディレクトリ用。権限要求を避ける
- `symlinkOrHardlink`: ファイル用。symlink、hardlink、copy の順に fallback
- `writeFile`: 生成ファイルを書き出す

NixOS:

- `outOfStoreSymlink`: 作業ツリーの実体へ writable link を張る
- `storeFile`: Nix store 由来の immutable file として配置する

実行時にツールが書き戻す可能性のある設定は `outOfStoreSymlink` を使う。Claude / Codex の設定はこの分類に入る。

## 整合性チェック

`check_contracts.ps1` は最低限、以下を検査する。

- `contracts/dotfiles.toml` が parse できる
- `id` が一意である
- `source` / `inputs` が存在する
- `kind = "file"` の source が file である
- `kind = "directory"` の source が directory である
- `scope = "shared"` の entry が Windows / NixOS 両方の target を持つ
- `scope = "windows"` の entry が Windows target を持つ
- `scope = "nixos"` の entry が NixOS target を持つ
- `.config/shared/*` の top-level unit が契約に登録されている
- OS ごとの target path が衝突しない
- generated file の target が通常 link target と衝突しない
- Windows 専用 source が `.config/shared` に混ざっていない
- NixOS 専用 source が `.config/shared` に混ざっていない

## 生成と適用

### NixOS

NixOS は TOML を直接読む。

```nix
let
  contract = builtins.fromTOML (builtins.readFile ../../contracts/dotfiles.toml);
in
{
  # contract.files から xdg.configFile / home.file を導出する
}
```

Home Manager の adapter は、`targets.nixos` がある entry だけを対象にする。

### Windows

Windows は PowerShell で適用する。

PowerShell 標準には TOML parser がないため、次のどちらかを採用する。

1. `taplo` などで TOML を JSON / PSD1 に変換し、生成済みファイルを commit する
2. `setup_windows.ps1` 実行前に `taplo` を要求し、実行時に TOML を読む

初期設計では 1 を推奨する。Windows bootstrap の依存を増やさず、`setup_windows.ps1` は `Import-PowerShellDataFile` で native data を読める。

```text
contracts/dotfiles.toml
  -> .generated/dotfiles.psd1
  -> scripts/setup_windows.ps1
```

## CI

`just ci` は以下を実行する。

```sh
just consistency
just syntax
alejandra --check .
taplo fmt --check contracts/*.toml
nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel
```

`just consistency` は以下を含む。

- 契約検証
- Windows 用生成ファイルが最新かの確認
- NixOS adapter が TOML から評価できることの確認

## tools.toml

ツールや package の整合性は dotfiles とは別契約にする。

Windows と NixOS では package manager と package 名が一致しないため、完全一致ではなく capability 単位で管理する。

```toml
[[tools]]
id = "neovim"
required_on = ["windows", "nixos"]

[tools.windows]
manager = "winget"
package = "Neovim.Neovim"

[tools.nixos]
package = "neovim"
group = "core"
```

最初の移行では `tools.toml` は作らず、dotfiles の契約化を優先する。

## 移行計画

1. `contracts/dotfiles.toml` の schema を確定する
2. 現在の `.config/shared` / `.config/windows` / `.config/nixos` を契約に登録する
3. PowerShell で `check_contracts.ps1` を実装する
4. `just consistency` と CI に契約検証を追加する
5. Windows setup の `$targets` を契約由来に置き換える
6. NixOS Home Manager の手書き link 定義を契約由来に置き換える
7. 既存の暫定 checker を削除する
8. 必要になった段階で `tools.toml` を追加する

## 判断

最初から chezmoi に寄せるより、この repository の既存構造に合わせて manifest 駆動にする。

これにより、NixOS は Nix の強みを維持し、Windows は PowerShell setup を維持しつつ、両 OS の dotfiles 配置だけを 1 つの契約で統制できる。
