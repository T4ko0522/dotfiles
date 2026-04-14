# Dotfiles

[![Windows](https://img.shields.io/badge/Windows-11-0078D4?logo=windows11&logoColor=white)](https://www.microsoft.com/windows/)
[![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![WezTerm](https://img.shields.io/badge/WezTerm-4E49EE?logo=wezterm&logoColor=white)](https://wezfurlong.org/wezterm/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7-5391FE?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![mise](https://img.shields.io/badge/mise-dev_tools-4E9A06?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTV6TTIgMTdsMTAgNSAxMC01TTIgMTJsMTAgNSAxMC01Ii8+PC9zdmc+)](https://mise.jdx.dev/)
[![License](https://img.shields.io/badge/License-Apache_2.0-D22128?logo=apache&logoColor=white)](LICENSE)

![sample](image.png)

## Description

Windows用に作成されたdotfiles.  
WSLを使用せずともWindows環境をLinux Likeにカスタマイズします。
> このdotfilesは [mozumasuさんのdotfiles](https://github.com/mozumasu/dotfiles) を参考に作られています。

## Tools

| カテゴリ | ツール |
| -------- | ------ |
| Terminal | [WezTerm](https://wezfurlong.org/wezterm/) |
| Shell | [PowerShell 7](https://github.com/PowerShell/PowerShell) + [Starship](https://starship.rs/) |
| Editor | [Neovim](https://neovim.io/) (LazyVim) |
| Font | [PlemolJP Console NF](https://github.com/yuru7/PlemolJP) / [JetBrainsMono NFP](https://www.jetbrains.com/lp/mono/) |
| File Manager | [yazi](https://github.com/sxyazi/yazi) |
| Dev Tools | [mise](https://mise.jdx.dev/) (Node, Bun, Deno, Go, Python, .NET, Terraform, etc.) |
| Status Bar | [YASB](https://github.com/amnweb/yasb) |

## Dependency

以下を事前にインストールしてください。ランタイム・CLIツールは `mise install` で追加されます。

- [Git](https://git-scm.com/)
- [PowerShell 7](https://github.com/PowerShell/PowerShell)
- [mise](https://mise.jdx.dev/)
- [WezTerm Nightly](https://wezfurlong.org/wezterm/)
- [Neovim](https://neovim.io/)
- [Git LFS](https://git-lfs.com/)
- [delta](https://github.com/dandavison/delta)
- [mpv.net](https://github.com/mpvnet-player/mpv.net)
- [Rustup](https://rustup.rs/)
- [cava](https://github.com/karlstav/cava)
- [MinGW](https://www.mingw-w64.org/) (TreeSitter ビルド用)
- [YASB](https://github.com/amnweb/yasb)
- [PlemolJP Console NF](https://github.com/yuru7/PlemolJP)
- [JetBrainsMono NFP](https://www.jetbrains.com/lp/mono/) (Nerd Fonts版)
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) (PSモジュール)

## Setup

```powershell
# 1. Clone
git clone https://github.com/T4ko0522/dotfiles
cd dotfiles

# 3. シンボリックリンク・設定の配置
pwsh -ExecutionPolicy Bypass -File .\.bin\setup_windows.ps1

# 4. mise でランタイム・CLI ツールをインストール
mise trust
mise install
```
