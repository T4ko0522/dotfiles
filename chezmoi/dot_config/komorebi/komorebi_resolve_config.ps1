# 接続中の外部モニターを WMI で検出して、komorebi 設定の
# display_index_preferences[1] を実機に合わせた一時ファイルを生成する。
# 標準出力に生成済みファイルのパスを 1 行で返す（komorebi_start.ps1 から
# `komorebic start --config <path>` 用に渡す）。
#
# canonical な komorebi.json は chezmoi が配置した $HOME\komorebi.json を
# 読み込み、リポジトリは書き換えない。
# 検出に失敗した場合は canonical のパスをそのまま返す（フォールバック）。

$ErrorActionPreference = "Continue"

# Canonical 設定ファイル
$canonicalPath = Join-Path $env:USERPROFILE "komorebi.json"
if (-not (Test-Path -LiteralPath $canonicalPath)) {
    throw "komorebi.json is not managed at: $canonicalPath"
}

# 認識済み外部モニター（後で増やす場合はここに追加）
$knownExternals = @{
    "IOD43EE" = "home (IO-DATA)"
    "DELF144" = "work (Dell)"
}

# 内蔵モニター（除外用）
$internalManufacturers = @("CMN", "AUO", "LGD", "BOE")

function ConvertTo-KomorebiDeviceId {
    param([string]$InstanceName)
    # InstanceName: "DISPLAY\IOD43EE\5&26d74eb9&0&UID4354_0"
    # komorebi:     "IOD43EE-5&26d74eb9&0&UID4354"
    $parts = $InstanceName -split '\\'
    if ($parts.Count -lt 3) { return $null }
    $deviceCode = $parts[1]
    $hardwareId = $parts[2] -replace '_\d+$', ''
    return "$deviceCode-$hardwareId"
}

# 外部モニター検出
$detectedExternalId = $null
try {
    $wmiMonitors = Get-CimInstance -Namespace root\WMI -ClassName WmiMonitorID -ErrorAction Stop |
        Where-Object { $_.Active }
    foreach ($wm in $wmiMonitors) {
        $mfg = ([System.Text.Encoding]::ASCII.GetString($wm.ManufacturerName)).TrimEnd([char]0)
        if ($internalManufacturers -contains $mfg) { continue }

        $prod = ([System.Text.Encoding]::ASCII.GetString($wm.ProductCodeID)).TrimEnd([char]0)
        $deviceCode = "$mfg$prod"
        if (-not $knownExternals.ContainsKey($deviceCode)) {
            Write-Host "[?] unknown external monitor: $deviceCode (komorebi_resolve_config.ps1 の knownExternals に追加してください)" -ForegroundColor Yellow
            continue
        }

        $detectedExternalId = ConvertTo-KomorebiDeviceId -InstanceName $wm.InstanceName
        Write-Host ("[ext] detected: {0}  ({1})" -f $detectedExternalId, $knownExternals[$deviceCode]) -ForegroundColor Cyan
        break
    }
} catch {
    Write-Host "WMI monitor lookup failed: $_" -ForegroundColor Yellow
}

# Canonical を読み込み、必要なら display_index_preferences[1] を patch
$json = Get-Content -LiteralPath $canonicalPath -Raw
$config = $json | ConvertFrom-Json

if ($detectedExternalId -and $config.display_index_preferences) {
    $current = $config.display_index_preferences.'1'
    if ($current -ne $detectedExternalId) {
        Write-Host ("[patch] display_index_preferences[1]: {0} -> {1}" -f $current, $detectedExternalId) -ForegroundColor DarkCyan
        $config.display_index_preferences.'1' = $detectedExternalId
    }
}

# app_specific_configuration_path は dotfiles canonical では PowerShell 風の "$Env:..." 表記だが、
# komorebi はこの形式を展開しないので、runtime 用には絶対パスへ解決しておく。
if ($config.app_specific_configuration_path) {
    $orig = $config.app_specific_configuration_path
    $resolved = $orig.Replace('$Env:USERPROFILE', $env:USERPROFILE).Replace('${Env:USERPROFILE}', $env:USERPROFILE).Replace('%USERPROFILE%', $env:USERPROFILE)
    if ($resolved -ne $orig) {
        Write-Host ("[patch] app_specific_configuration_path: {0} -> {1}" -f $orig, $resolved) -ForegroundColor DarkCyan
        $config.app_specific_configuration_path = $resolved
    }
}

# 一時設定ファイルへ書き出し
$runtimePath = Join-Path $env:LOCALAPPDATA "komorebi-runtime.json"
$config | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $runtimePath -Encoding UTF8

# stdout には生成済みファイルパスのみ
Write-Output $runtimePath
