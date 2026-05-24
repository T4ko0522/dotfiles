# Dotfiles
Windowsを使いましょう！！！！

[![Windows](https://img.shields.io/badge/Windows-11-0078D4?logo=windows11&logoColor=white)](https://www.microsoft.com/windows/)
[![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![WezTerm](https://img.shields.io/badge/WezTerm-4E49EE?logo=wezterm&logoColor=white)](https://wezfurlong.org/wezterm/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7-5391FE?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![mise](https://img.shields.io/badge/mise-dev_tools-4E9A06?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTV6TTIgMTdsMTAgNSAxMC01TTIgMTJsMTAgNSAxMC01Ii8+PC9zdmc+)](https://mise.jdx.dev/)  
Is this Windows? for real?
![sample](image.png)

## Setup

```powershell
# 1. Clone
git clone https://github.com/T4ko0522/dotfiles
cd dotfiles

# 2. 依存関係を一括インストール (管理者の pwsh で実行)
#    winget で必須群 → Scoop → bucket (extras / nerd-fonts / t4ko0522) → CLI ツール
pwsh -ExecutionPolicy Bypass -File .\.bin\bootstrap.ps1

# 3. シンボリックリンク・設定の配置
pwsh -ExecutionPolicy Bypass -File .\.bin\setup_windows.ps1

# 4. mise でランタイム・CLI ツールをインストール
mise trust
mise install
```

## Claude Code Switch

```powershell
# native installer -> claude
pwsh -ExecutionPolicy Bypass -File .\.bin\switch_claude_code.ps1 native

# mise npm install -> claude
pwsh -ExecutionPolicy Bypass -File .\.bin\switch_claude_code.ps1 npm

# show current launcher status
pwsh -ExecutionPolicy Bypass -File .\.bin\switch_claude_code.ps1 status
```
