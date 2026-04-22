# 接続中のモニターを検出して komorebi に display index を適用する。
# 自宅 (IOD43EE) と職場 (DELF144) で外部モニターが切替わるため、
# 静的な komorebi.json では片方しか想定できない。このスクリプトで実行時に補正する。

$ErrorActionPreference = "Continue"

# 既知のモニター
$mainId       = "CMN1556-4&243a609a&0&UID8388688"
$externalIds  = @{
    "IOD43EE-5&26d74eb9&0&UID4354" = "home (IO-DATA)"
    "DELF144-5&26d74eb9&0&UID4354" = "work (Dell)"
}

if (-not (Get-Command komorebic -ErrorAction SilentlyContinue)) {
    Write-Host "komorebic not found in PATH" -ForegroundColor Yellow
    exit 1
}

try {
    $monitors = komorebic monitor-information 2>$null | ConvertFrom-Json
} catch {
    Write-Host "komorebi is not running (start it first)" -ForegroundColor Yellow
    exit 1
}

if (-not $monitors) {
    Write-Host "no monitors detected" -ForegroundColor Yellow
    exit 1
}

foreach ($m in $monitors) {
    if ($m.device_id -eq $mainId) {
        komorebic display-index-preference 0 $m.device_id | Out-Null
        Write-Host ("[main] index 0 -> {0}" -f $m.device_id) -ForegroundColor Cyan
    } elseif ($externalIds.ContainsKey($m.device_id)) {
        komorebic display-index-preference 1 $m.device_id | Out-Null
        $label = $externalIds[$m.device_id]
        Write-Host ("[ext ] index 1 -> {0}  ({1})" -f $m.device_id, $label) -ForegroundColor Cyan
    } else {
        Write-Host ("[?] unknown monitor: {0}" -f $m.device_id) -ForegroundColor Yellow
        Write-Host ("    -> apply_monitor_preferences.ps1 の `$externalIds` に登録してください") -ForegroundColor DarkGray
    }
}

# 設定変更後に再タイル
komorebic retile | Out-Null
