# komorebi + whkd + 常用アプリ一括起動を「実機モニターに合わせた
# display_index_preferences」で行う、朝の作業環境立ち上げの唯一の経路。
# pwsh 起動時に startup.ps1 から komorebi 未起動時のみ呼ばれる。
#
# 注意: `komorebic start --config <path>` は内部で `--config="path"` の形に連結して
# komorebi.exe に渡すため clap で reject される。これを避けるために komorebi.exe を
# 直接起動し、その後 whkd を別途立ち上げる。

$ErrorActionPreference = "Continue"

$komorebiPath = (Get-Command komorebi -ErrorAction SilentlyContinue)?.Source
$whkdPath = (Get-Command whkd -ErrorAction SilentlyContinue)?.Source
if (-not $komorebiPath) {
    Write-Host "komorebi not found in PATH" -ForegroundColor Yellow
    exit 1
}

# 接続モニターに合わせて patch 済みの一時設定ファイルを生成
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolver = Join-Path $scriptDir "komorebi_resolve_config.ps1"
$runtimeConfig = $null
if (Test-Path -LiteralPath $resolver) {
    $output = & $resolver
    $last = $output | Where-Object { $_ } | Select-Object -Last 1
    if ($last) { $runtimeConfig = $last.ToString().Trim() }
}

# komorebi.exe を直接起動 (komorebic start の --config 連結バグを回避)
$komorebiArgs = @()
if ($runtimeConfig -and (Test-Path -LiteralPath $runtimeConfig)) {
    $komorebiArgs = @('--config', $runtimeConfig)
    Write-Host ("[start] komorebi --config {0}" -f $runtimeConfig) -ForegroundColor Cyan
} else {
    Write-Host "[start] komorebi (no runtime config)" -ForegroundColor Cyan
}
Start-Process -FilePath $komorebiPath -ArgumentList $komorebiArgs -WindowStyle Hidden

# komorebi が socket を listen し始めるまで待機 (最大 15 秒)
$deadline = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 300
    komorebic state 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
}

# whkd を別途立ち上げ
if ($whkdPath) {
    if (-not (Get-Process -Name whkd -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $whkdPath -WindowStyle Hidden
        Write-Host "[start] whkd" -ForegroundColor Cyan
    }
}

# 常用アプリを一括起動して両モニターを WS1 に整列
# komorebi 未起動 → 起動の流れでだけ走るので、作業中の pwsh タブ起動では
# 二度目の WS リセットは発生しない。
$morningSetup = Join-Path $scriptDir "morning_setup.ps1"
if (Test-Path -LiteralPath $morningSetup) {
    Write-Host "[start] morning_setup" -ForegroundColor Cyan
    & $morningSetup
}
