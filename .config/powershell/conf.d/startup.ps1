# Terminal-Icons をアイドル時にバックグラウンドロード（プロンプト表示後に実行）
$global:_lsGlyphs = $null
$global:_lsTheme = $null
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    if (Get-Module Terminal-Icons -ErrorAction SilentlyContinue) {
        $global:_lsGlyphs = @{}
        Get-TerminalIconsGlyphs | ForEach-Object { $global:_lsGlyphs[$_.Name] = $_.Value }
        $global:_lsTheme = Get-TerminalIconsTheme
    }
} | Out-Null

# https://github.com/antfu-collective/ni とNew-Itemの競合を無効化
Remove-Item Alias:ni -Force -ErrorAction Ignore

# komorebi + whkd 自動起動
if ((Get-Command komorebic -ErrorAction SilentlyContinue) -and
    -not (Get-Process -Name komorebi -ErrorAction SilentlyContinue)) {
    Start-Process komorebic -ArgumentList 'start', '--whkd' -WindowStyle Hidden
}

# yasb 自動起動
if (-not (Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
    Start-Process yasb -WindowStyle Hidden
}

# Starship プロンプト初期化（キャッシュで高速化）
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $starshipCache = Join-Path $env:LOCALAPPDATA "starship_init.ps1"
    $starshipBin = (Get-Command starship).Source
    if ((Test-Path $starshipCache) -and (Get-Item $starshipCache).LastWriteTime -gt (Get-Item $starshipBin).LastWriteTime) {
        . $starshipCache
    } else {
        $initScript = & starship init powershell --print-full-init
        $initScript | Set-Content -LiteralPath $starshipCache -Encoding UTF8
        Invoke-Expression $initScript
    }
}