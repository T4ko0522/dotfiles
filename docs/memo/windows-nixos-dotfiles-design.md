# Windows / NixOS / WSL dotfiles設計

## 目的

chezmoiとNixの責務を分離し、Windows、NixOS、Windows上のNixOS-WSLを同じリポジトリから管理する。1つのtarget pathを複数の仕組みで所有しないことを最優先の不変条件とする。

## 決定事項

- chezmoiはHybrid方式で採用する。
- chezmoi source rootはリポジトリ直下の`chezmoi/`とする。
- 静的なcopy・templateは`chezmoi/`に置く。
- アプリが書き戻す設定や直接参照する実体は`mutable/`に置く。
- NixOSのsystem、package、service、desktop生成設定、nixvimはNixが所有する。
- WindowsはLazyVim、NixOSはnixvimを使用する。
- NixOS-WSLではnixvimおよびchezmoi管理のNeovim設定を使用しない。
- Linuxのユーザー名はNixOS、NixOS-WSLともに`t4ko`へ統一する。
- chezmoiはHome Manager activationから実行せず、明示的に`chezmoi apply`する。

## ディレクトリ構成

```text
dotfiles/
  .chezmoiroot                 # chezmoiを指す
  chezmoi/                     # chezmoi source root
    .chezmoi.toml.tmpl
    .chezmoiignore
    dot_config/
  mutable/                     # chezmoi変換対象外の書き込み可能な実体
    shared/
    nvim/                      # Windows LazyVim
    cava/                      # Windows Cava runtime files
    nixos/
  nix-configs/                 # NixOS、Home Manager、nixvim
  scripts/                     # bootstrapとCI契約検査のみ
  docs/
```

`mutable/`はchezmoi source rootの外に置く。これにより`mutable/`自体が誤ってホームディレクトリへ配置されることを防ぐ。

## 所有権

機械可読な目標状態は`docs/memo/dotfiles-ownership.tsv`で管理する。

```text
(profile, target path) -> exactly one owner
```

ownerは次のいずれかとする。

- `chezmoi`: copy、template、symlink、Windows junction
- `nix`: NixOSまたはHome Managerによる生成・配置
- `unmanaged`: 意図的に配置しない

移行時は必ず既存ownerからtargetを削除してから新ownerへ追加する。同じコミット内でも、この順序でactivationとapplyを確認する。

## 環境別の責務

| 対象 | Windows | NixOS | NixOS-WSL |
|---|---|---|---|
| system / service | Windows | NixOS | NixOS-WSL |
| package | winget / Scoop / mise | Nix / Home Manager | Nix / Home Manager |
| Neovim | chezmoi + LazyVim | Nix + nixvim | 管理しない |
| shell | chezmoi + PowerShell | Home Manager + zsh | Home Manager + zsh |
| Git / Starship / Yazi / Lazygit | chezmoi | chezmoi | chezmoi |
| WezTerm | chezmoi | chezmoi | 管理しない |
| YASB | chezmoi | 対象外 | 対象外 |
| niri / waybar / swaync | 対象外 | Nix | 対象外 |
| `/etc/wsl.conf` | 対象外 | 対象外 | NixOS-WSL |

## Neovim

### Windows

LazyVimの実体を`mutable/nvim`へ置き、`%LOCALAPPDATA%\nvim`からjunctionで参照する。Windowsのdirectory symlink権限に依存しないよう、chezmoiの`run_after_` PowerShell scriptでjunctionを収束させる。

### NixOS

`feat/nixvim`でnixvimへの移行を完了した。Home Managerの`programs.neovim`と`~/.config/nvim` linkは撤去済みで、Nixvim設定は`nix-configs/home/modules/editors/nixvim`が所有する。

### NixOS-WSL

nixvimをimportせず、chezmoiでも`~/.config/nvim`を生成しない。将来editorが必要になった場合は、この所有権を明示的に再決定する。

## chezmoi profile

初期化時に次のprofileを選択し、chezmoi configの`data.profile`へ保存する。

- `windows`
- `nixos`
- `wsl`

`.chezmoi.os`だけではNixOSとNixOS-WSLを区別できないため、OS判定の代わりにprofileをtarget選択へ使用する。ユーザー名は全Linux環境で`t4ko`とする。

## 移行フェーズ

### Phase 0: 契約とPoC

- source root、profile、所有権表を追加する。
- 3 profileのtemplateを非対話で評価する。
- Windows junctionを一時ディレクトリで検証する。
- Claude settingsのmerge結果をfixture化する。
- Nix/Home Managerとchezmoiのtarget交差検査を追加する。

### Phase 1: NixOS-WSL

実装済み。`nixosConfigurations.wsl`と`nix-configs/hosts/wsl/home.nix`を入口とする。

- `nixos-wsl` inputと`nixosConfigurations.wsl`を追加する。
- usernameとhome directoryをホスト引数化する。
- desktopを含まないHome Manager profileを作る。
- `/etc/wsl.conf`とWindows interopをNixで管理する。

### Phase 2: Windows

- Windows LazyVimとcavaを`mutable`へ移し、chezmoiのjunction所有へ切り替えた。
- PowerShell、YASB、mise、ccwin-notifyをchezmoi sourceへ移した。
- 独自の`setup_windows.ps1`を廃止し、`bootstrap.ps1`からchezmoiを直接適用する。

### Phase 3: NixOS nixvim

- `feat/nixvim`でNixOSのnixvim移行を完了した。
- LazyVimとの機能差分を必要に応じて追跡する。

### Phase 4: 共有設定

- Starship、Fastfetch、Git、Vim、Yazi、Lazygit、WezTerm、Zedをchezmoiへ移した。
- 書き戻し対象だけを`mutable/shared`へ置いた。
- Home Managerの所有をNix固有targetだけへ縮小した。

### Phase 5: 整理

- Claude settings生成のNix/PowerShell二重実装をchezmoi templateへ統合した。
- 存在しないsourceを参照する旧Windows設定と補助scriptを削除した。
- GitHub ActionsでNixOS 4構成とWindows profileの可用性を検証する。

## 検証

```sh
just chezmoi-check
just syntax
just ci
```

移行中も既存環境へ直接applyするテストは行わず、一時HOMEまたはdry-runで確認してから実機へ適用する。
