# ワークスペース配置に沿ってよく使うアプリを一括起動する。
# 振り分けは komorebi.json の workspace_rules 側で宣言的に管理しているため、
# このスクリプトは起動だけを担当する（timing 依存を排除）。
#
# 仕様:
#   - 既に走っているプロセスは何もしない
#   - インストール先が見つからない exe はスキップ
#   - 全て実体フルパスで起動（PATH 依存を排除）

$ErrorActionPreference = "Continue"

# モニター index の動的補正（自宅／職場で外部モニターが変わるため）
& (Join-Path $PSScriptRoot "apply_monitor_preferences.ps1")

function Start-IfNotRunning {
    param(
        [Parameter(Mandatory)][string]   $ProcessName,
        [Parameter(Mandatory)][string]   $Path,
        [string[]]                       $ArgumentList
    )

    if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
        Write-Host ("[skip] already running: {0}" -f $ProcessName) -ForegroundColor DarkGray
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("[miss] not installed: {0}" -f $Path) -ForegroundColor Yellow
        return
    }

    Write-Host ("[run ] launching: {0}" -f $Path) -ForegroundColor Cyan
    if ($ArgumentList) {
        Start-Process -FilePath $Path -ArgumentList $ArgumentList
    } else {
        Start-Process -FilePath $Path
    }
    Start-Sleep -Milliseconds 300
}

# WS I / M0 — WezTerm
Start-IfNotRunning `
    -ProcessName "wezterm-gui" `
    -Path        "C:\Program Files\WezTerm\wezterm-gui.exe"

# WS II / M0 — Discord (Update.exe --processStart Discord.exe でバージョン依存を回避)
Start-IfNotRunning `
    -ProcessName "Discord" `
    -Path        "$env:LOCALAPPDATA\Discord\Update.exe" `
    -ArgumentList @("--processStart", "Discord.exe")

# WS III / M0 — Slack (Microsoft Store 版。WindowsApps 以下の App Execution Alias を使う)
Start-IfNotRunning `
    -ProcessName "slack" `
    -Path        "$env:LOCALAPPDATA\Microsoft\WindowsApps\slack.exe"

# WS III / M0 — Spotify
Start-IfNotRunning `
    -ProcessName "Spotify" `
    -Path        "$env:APPDATA\Spotify\Spotify.exe"

# WS V / M1 — VSCode
Start-IfNotRunning `
    -ProcessName "Code" `
    -Path        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

# WS V / M1 — Brave
Start-IfNotRunning `
    -ProcessName "brave" `
    -Path        "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"

# WS VII / M1 — Chrome
Start-IfNotRunning `
    -ProcessName "chrome" `
    -Path        "C:\Program Files\Google\Chrome\Application\chrome.exe"

# 起動完了後に両モニターを WS 1 へ
Start-Sleep -Seconds 2
if (Get-Command komorebic -ErrorAction SilentlyContinue) {
    komorebic focus-workspaces 0 | Out-Null
}
