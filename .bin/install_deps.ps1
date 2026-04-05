$ErrorActionPreference = "Stop"

# =============================================================================
# install_deps.ps1 — mise install では入らない依存関係を自動インストール
# =============================================================================
# 使い方: pwsh -ExecutionPolicy Bypass -File .bin\install_deps.ps1
# setup_windows.ps1 とは独立して実行する

# ---------------------------------------------------------------------------
# Helper: コマンドの存在チェック
# ---------------------------------------------------------------------------
function Test-CommandExists($cmd) {
  return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------
# Helper: winget パッケージのインストール（未インストール時のみ）
# ---------------------------------------------------------------------------
function Install-WingetPackage($id, $name) {
  $installed = winget list --id $id --accept-source-agreements 2>$null
  if ($installed -match [regex]::Escape($id)) {
    Write-Host "[skip] $name は既にインストール済み" -ForegroundColor DarkGray
    return
  }
  Write-Host "[install] $name ($id) ..." -ForegroundColor Cyan
  winget install --id $id --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[warn] $name のインストールに失敗しました" -ForegroundColor Yellow
  }
}

# ---------------------------------------------------------------------------
# Helper: scoop パッケージのインストール（未インストール時のみ）
# ---------------------------------------------------------------------------
function Install-ScoopPackage($pkg, $name, $bucket) {
  if ($bucket) {
    $knownBuckets = scoop bucket list 2>$null | ForEach-Object { $_.Name }
    if ($knownBuckets -notcontains $bucket) {
      Write-Host "[bucket] scoop bucket add $bucket ..." -ForegroundColor Cyan
      scoop bucket add $bucket
    }
  }

  $scoopList = scoop list 2>$null | ForEach-Object { $_.Name }
  if ($scoopList -contains $pkg) {
    Write-Host "[skip] $name は既にインストール済み (scoop)" -ForegroundColor DarkGray
    return
  }
  Write-Host "[install] $name ($pkg) via scoop ..." -ForegroundColor Cyan
  scoop install $pkg
}

# ---------------------------------------------------------------------------
# Helper: フォントのダウンロード＆インストール
# ---------------------------------------------------------------------------
function Install-FontFromGitHub($repoOwner, $repoName, $assetPattern, $fontName) {
  # フォント名でインストール済みチェック
  $installedFonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
  if ($installedFonts -contains $fontName) {
    Write-Host "[skip] $fontName は既にインストール済み" -ForegroundColor DarkGray
    return
  }

  Write-Host "[install] $fontName をダウンロード中..." -ForegroundColor Cyan

  # GitHub API で最新リリースの該当アセットURLを取得
  $releaseUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
  $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ "User-Agent" = "dotfiles-setup" }
  $asset = $release.assets | Where-Object { $_.name -like $assetPattern } | Select-Object -First 1
  if (-not $asset) {
    Write-Host "[warn] $fontName のリリースアセットが見つかりません (pattern: $assetPattern)" -ForegroundColor Yellow
    return
  }

  $tmpDir = Join-Path $env:TEMP "dotfiles_font_install"
  $zipPath = Join-Path $tmpDir $asset.name
  $extractDir = Join-Path $tmpDir ($asset.name -replace '\.zip$', '')

  try {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    # ttf/otf ファイルをユーザーフォントフォルダにコピー
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null

    $fontFiles = Get-ChildItem -Path $extractDir -Recurse -Include "*.ttf", "*.otf"
    $regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

    foreach ($f in $fontFiles) {
      $dst = Join-Path $fontDir $f.Name
      Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
      # レジストリにフォントを登録
      $fontRegName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name) + " (TrueType)"
      New-ItemProperty -Path $regPath -Name $fontRegName -Value $dst -PropertyType String -Force | Out-Null
    }
    Write-Host "[done] $fontName をインストールしました ($($fontFiles.Count) files)" -ForegroundColor Green
  } finally {
    if (Test-Path $tmpDir) {
      Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

# =============================================================================
# 1. scoop のインストール（未インストール時）
# =============================================================================
if (-not (Test-CommandExists "scoop")) {
  Write-Host "[install] scoop をインストール中..." -ForegroundColor Cyan
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

# =============================================================================
# 2. winget パッケージ
# =============================================================================
Write-Host "`n=== winget packages ===" -ForegroundColor White

$wingetPackages = @(
  @{ Id = "Git.Git";                Name = "Git" },
  @{ Id = "Microsoft.PowerShell";   Name = "PowerShell 7" },
  @{ Id = "jdx.mise";               Name = "mise" },
  @{ Id = "wez.wezterm";            Name = "WezTerm" },
  @{ Id = "Neovim.Neovim";          Name = "Neovim" },
  @{ Id = "GitHub.GitLFS";          Name = "git-lfs" },
  @{ Id = "dandavison.delta";       Name = "delta" },
  @{ Id = "stax76.mpv.net";          Name = "mpv.net" },
  @{ Id = "Anysphere.Cursor";       Name = "Cursor" },
  @{ Id = "Rustlang.Rustup";        Name = "Rustup" }
)

foreach ($pkg in $wingetPackages) {
  Install-WingetPackage -id $pkg.Id -name $pkg.Name
}

# =============================================================================
# 3. scoop パッケージ
# =============================================================================
Write-Host "`n=== scoop packages ===" -ForegroundColor White

Install-ScoopPackage -pkg "git-secrets" -name "git-secrets"
Install-ScoopPackage -pkg "mingw"       -name "MinGW (gcc for TreeSitter)"
Install-ScoopPackage -pkg "yasb"        -name "YASB"  -bucket "extras"
Install-ScoopPackage -pkg "cava"        -name "cava" -bucket "extras"

# =============================================================================
# 4. フォント
# =============================================================================
Write-Host "`n=== fonts ===" -ForegroundColor White

Add-Type -AssemblyName System.Drawing

Install-FontFromGitHub `
  -repoOwner "yuru7" `
  -repoName "PlemolJP" `
  -assetPattern "PlemolJP_NF_*.zip" `
  -fontName "PlemolJP Console NF"

Install-ScoopPackage -pkg "JetBrainsMono-NF-Propo" -name "JetBrainsMono NFP" -bucket "nerd-fonts"

# Cascadia Mono は Windows 11 に標準搭載のため省略

# =============================================================================
# 5. PowerShell モジュール
# =============================================================================
Write-Host "`n=== PowerShell modules ===" -ForegroundColor White

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
  Write-Host "[install] Terminal-Icons ..." -ForegroundColor Cyan
  Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
} else {
  Write-Host "[skip] Terminal-Icons は既にインストール済み" -ForegroundColor DarkGray
}

# =============================================================================
# 6. git-lfs の初期化
# =============================================================================
if (Test-CommandExists "git-lfs") {
  Write-Host "`n[setup] git-lfs install ..." -ForegroundColor Cyan
  git lfs install
}

# =============================================================================
# 6. PATH の更新を反映（新規インストール分）
# =============================================================================
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`n=== 依存関係のインストールが完了しました ===" -ForegroundColor Green
