# モジュール分割されたプロファイルを1ファイルにインライン展開し、
# コメント・空行を除去して高速化した $PROFILE を書き出す。
# setup_windows.ps1 から呼ばれる。

param(
  [Parameter(Mandatory = $false)]
  [string]$SourcePath,
  [Parameter(Mandatory = $false)]
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"

if (-not $SourcePath) {
  $repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  $SourcePath = Join-Path $repo ".config/powershell/Microsoft.PowerShell_profile.ps1"
}
if (-not $OutputPath) {
  $OutputPath = $PROFILE
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
  Write-Error "Source profile not found: $SourcePath"
}

$sourceDir = Split-Path -Parent $SourcePath
$content = Get-Content -LiteralPath $SourcePath -Raw

# dot-source 行を対象ファイルの中身でインライン展開する
# パターン: . "$modulesDir\foo.ps1" → modules/foo.ps1 を読み込み
$content = [regex]::Replace($content, '^\.\s+"?\$modulesDir\\([^"]+)"?\s*$', {
  param($m)
  $modulePath = Join-Path $sourceDir "conf.d/$($m.Groups[1].Value)"
  if (Test-Path -LiteralPath $modulePath) {
    Get-Content -LiteralPath $modulePath -Raw
  } else {
    Write-Warning "Module not found, skipping: $modulePath"
    ""
  }
}, [System.Text.RegularExpressions.RegexOptions]::Multiline)

# $modulesDir 定義行を除去（インライン展開後は不要）
$content = $content -replace '(?m)^\$modulesDir\s*=.*$', ''

# ブロックコメント除去
$content = $content -replace '(?s)<#.*?#>', ''

# 行コメント・空行を除去
$lines = $content -split "`r?`n"
$kept = $lines | ForEach-Object {
  $t = $_.Trim()
  if ($t -eq '') { return $null }
  if ($t.StartsWith('#')) { return $null }
  $_
} | Where-Object { $null -ne $_ }

$output = ($kept -join "`n").Trim()
Set-Content -LiteralPath $OutputPath -Value $output -Encoding UTF8
Write-Host "Wrote optimized profile ($($kept.Count) lines): $OutputPath"
