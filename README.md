# Dotfiles

![sample](image.png)

## Description

Windows用に作成されたdotfiles.
WindowsをLinux Likeにカスタマイズします。

## Dependency

依存関係は `install_deps.ps1` と `mise install` で自動インストールされます。

## Setup

```powershell
# 1. Clone
git clone https://github.com/T4ko0522/dotfiles
cd dotfiles

# 2. 依存関係のインストール
pwsh -ExecutionPolicy Bypass -File .\.bin\install_deps.ps1

# 3. シンボリックリンク・設定の配置
pwsh -ExecutionPolicy Bypass -File .\.bin\setup_windows.ps1

# 4. mise でランタイム・CLI ツールをインストール
mise trust
mise install
```
