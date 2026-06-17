#!/usr/bin/env pwsh
# -----------------------------------------------------------------------------
# bootstrap.ps1 — dotfiles の依存関係を一括インストール
# 完了後 `scripts\setup_windows.ps1` を実行してリンクを張る。
# -----------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. 管理者権限チェック
# ---------------------------------------------------------------------------
$principal = [Security.Principal.WindowsPrincipal]::new(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)
$isAdmin = $principal.IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
  Write-Host "[ERROR] 管理者権限が必要です。" -ForegroundColor Red
  Write-Host "管理者として PowerShell 7 を起動し直して、もう一度実行してください:" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  Start-Process pwsh -Verb RunAs -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File',`"$PSCommandPath`"" -ForegroundColor Cyan
  Write-Host ""
  exit 1
}
Write-Host "[OK] 管理者権限で実行中" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. winget の存在確認
# ---------------------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "[ERROR] winget が見つかりません。Microsoft Store の `App Installer` から導入してください。" -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------------------
# 3. winget パッケージ定義
# ---------------------------------------------------------------------------
# README の Dependency セクション + 現環境 (winget list) に基づき選定。
# Scoop 本体は winget リポジトリに無いため (4) で公式スクリプトを使用する。
$wingetPackages = @(
  @{ Id = 'Git.Git';                Name = 'Git' }
  @{ Id = 'GitHub.GitLFS';          Name = 'Git LFS' }
  @{ Id = 'Microsoft.PowerShell';   Name = 'PowerShell 7' }
  @{ Id = 'dandavison.delta';       Name = 'delta' }
  @{ Id = 'Neovim.Neovim';          Name = 'Neovim' }
  @{ Id = 'wez.wezterm.nightly';    Name = 'WezTerm Nightly' }
  @{ Id = 'Rustlang.Rustup';        Name = 'Rustup' }
  @{ Id = 'karlstav.cava';          Name = 'cava' }
  @{ Id = 'AmN.yasb';               Name = 'YASB' }
  @{ Id = 'mpv.net';                Name = 'mpv.net' }
)

function Test-WingetInstalled {
  param([string]$Id)
  $null = winget list --id $Id --exact --source winget --accept-source-agreements 2>$null
  return $LASTEXITCODE -eq 0
}

Write-Host "`n=== winget install ===" -ForegroundColor White
foreach ($p in $wingetPackages) {
  if (Test-WingetInstalled -Id $p.Id) {
    Write-Host "  Skip (installed): $($p.Name) [$($p.Id)]" -ForegroundColor DarkGray
    continue
  }
  Write-Host "  Install: $($p.Name) [$($p.Id)]" -ForegroundColor Cyan
  winget install --id $p.Id --exact --silent --source winget `
    --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "    -> 失敗 (exit=$LASTEXITCODE) 続行します。" -ForegroundColor Yellow
  }
}

# ---------------------------------------------------------------------------
# 4. Scoop 本体
# ---------------------------------------------------------------------------
Write-Host "`n=== Scoop install ===" -ForegroundColor White
if (Get-Command scoop -ErrorAction SilentlyContinue) {
  Write-Host "  Skip (installed): Scoop" -ForegroundColor DarkGray
} else {
  Write-Host "  Install: Scoop (公式スクリプト + -RunAsAdmin)" -ForegroundColor Cyan
  $installer = Invoke-RestMethod -Uri 'https://get.scoop.sh'
  Invoke-Expression "& { $installer } -RunAsAdmin"
}

# 新しく入った scoop / git などを PATH に引き当てる
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Write-Host "[ERROR] scoop が PATH に見つかりません。新しいシェルで再実行してください。" -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------------------
# 5. Scoop bucket
# ---------------------------------------------------------------------------
$scoopBuckets = @(
  @{ Name = 'extras';     Url = $null }
  @{ Name = 'nerd-fonts'; Url = $null }
  @{ Name = 't4ko0522';   Url = 'https://github.com/T4ko0522/tap' }
)

Write-Host "`n=== scoop bucket ===" -ForegroundColor White
$existingBuckets = @()
$bucketLines = (scoop bucket list 2>$null) -split "`r?`n"
foreach ($line in $bucketLines) {
  if ($line -match '^\s*([A-Za-z0-9_-]+)\s+https?://') {
    $existingBuckets += $matches[1]
  }
}
foreach ($b in $scoopBuckets) {
  if ($existingBuckets -contains $b.Name) {
    Write-Host "  Skip (added): $($b.Name)" -ForegroundColor DarkGray
    continue
  }
  Write-Host "  Add bucket: $($b.Name)" -ForegroundColor Cyan
  if ($b.Url) {
    scoop bucket add $b.Name $b.Url
  } else {
    scoop bucket add $b.Name
  }
}

# ---------------------------------------------------------------------------
# 6. Scoop パッケージ (bucket/app 形式で衝突を回避)
# ---------------------------------------------------------------------------
$scoopPackages = @(
  'main/7zip',
  'main/ffmpeg',
  'main/gcc',
  'main/starship',
  'main/mise',
  'extras/komorebi',
  'extras/whkd',
  'extras/lazygit',
  'extras/yazi',
  'extras/fastfetch',
  'extras/ghq',
  'extras/peco',
  'nerd-fonts/JetBrainsMono-NF-Propo',
  't4ko0522/ccwin',
  't4ko0522/spt'
)

Write-Host "`n=== scoop install ===" -ForegroundColor White
$installedApps = @()
try {
  $exportJson = scoop export 2>$null | Out-String
  if ($exportJson) {
    $export = $exportJson | ConvertFrom-Json
    $installedApps = @($export.apps | ForEach-Object { $_.Name.ToLower() })
  }
} catch {
  Write-Host "  Warning: scoop export の解析に失敗しました ($($_.Exception.Message))" -ForegroundColor Yellow
}
foreach ($pkg in $scoopPackages) {
  $appName = ($pkg -replace '.*/').ToLower()
  if ($installedApps -contains $appName) {
    Write-Host "  Skip (installed): $pkg" -ForegroundColor DarkGray
    continue
  }
  Write-Host "  Install: $pkg" -ForegroundColor Cyan
  scoop install $pkg
  if ($LASTEXITCODE -ne 0) {
    Write-Host "    -> 失敗 (exit=$LASTEXITCODE) 続行します。" -ForegroundColor Yellow
  }
}

Write-Host "`n[OK] Bootstrap completed." -ForegroundColor Green
Write-Host "次に: pwsh -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1" -ForegroundColor White
