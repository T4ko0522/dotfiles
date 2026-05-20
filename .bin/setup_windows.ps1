$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$homeDir = [Environment]::GetFolderPath("UserProfile")
$localDir = [Environment]::GetFolderPath("LocalApplicationData")
$roamingDir = [Environment]::GetFolderPath("ApplicationData")
$binDir = Join-Path $repo ".bin"

# Src: repo からの相対パス
# Dst: 相対パス → $homeDir 基準、絶対パス → そのまま使用
$targets = @(
  @{ Src = ".gitconfig";            Dst = ".gitconfig" },
  @{ Src = ".config/claude";        Dst = ".claude" },
  @{ Src = ".config/codex";         Dst = ".codex" },
  @{ Src = ".config/lazygit";       Dst = ".config/lazygit" },
  @{ Src = ".config/mise";          Dst = ".config/mise" },
  @{ Src = ".config/nvim";          Dst = (Join-Path $localDir "nvim") },
  @{ Src = ".config/vim";           Dst = ".config/vim" },
  @{ Src = ".config/wezterm";       Dst = ".config/wezterm" },
  @{ Src = ".config/yazi";          Dst = (Join-Path $roamingDir "yazi\config") },
  @{ Src = ".config/starship.toml"; Dst = ".config/starship.toml" },
  @{ Src = ".config/ccwin-notify";  Dst = ".config/ccwin-notify" },
  @{ Src = ".config/yasb";          Dst = ".config/yasb" },
  @{ Src = ".config/cava";          Dst = ".config/cava" },
  @{ Src = ".config/fastfetch";     Dst = ".config/fastfetch" },
  @{ Src = ".config/komorebi/komorebi.json";     Dst = "komorebi.json" },
  @{ Src = ".config/komorebi/komorebi.bar.json"; Dst = "komorebi.bar.json" },
  @{ Src = ".config/komorebi/applications.json"; Dst = "applications.json" },
  @{ Src = ".config/whkdrc";        Dst = ".config/whkdrc" },
  @{ Src = ".config/vscode/settings.json";    Dst = (Join-Path $roamingDir "Code\User\settings.json") },
  @{ Src = ".config/vscode/keybindings.json"; Dst = (Join-Path $roamingDir "Code\User\keybindings.json") },
  @{ Src = ".config/vscode/snippets";         Dst = (Join-Path $roamingDir "Code\User\snippets") },
  @{ Src = ".config/zed/settings.json";       Dst = (Join-Path $roamingDir "Zed\settings.json") },
  @{ Src = ".config/zed/keymap.json";         Dst = (Join-Path $roamingDir "Zed\keymap.json") },
  @{ Src = ".config/zed/tasks.json";          Dst = (Join-Path $roamingDir "Zed\tasks.json") }
)

function Remove-ExistingPath($path) {
  if (-not (Test-Path -LiteralPath $path)) {
    return $true
  }

  # Replace any existing path (file/dir/link) so setup always converges
  try {
    Remove-Item -LiteralPath $path -Force -Recurse -ErrorAction Stop
  } catch {
    # 過去に管理者で作られた壊れた reparse point は Remove-Item が Access denied になる。
    # cmd /c rmdir|del は別経路で reparse point を消せるため最終フォールバックに使う。
    if (Test-Path -LiteralPath $path -PathType Container) {
      Get-ChildItem -LiteralPath $path -Recurse -Force | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
        try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch {
          Write-Host "Warning: Skipped locked file: $($_.FullName)" -ForegroundColor Yellow
        }
      }
      try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop } catch {
        & cmd.exe /c "rmdir /S /Q `"$path`"" 2>&1 | Out-Null
      }
    } else {
      & cmd.exe /c "del /F /Q `"$path`"" 2>&1 | Out-Null
    }
    if (Test-Path -LiteralPath $path) {
      Write-Host "Warning: Could not remove path: $path" -ForegroundColor Yellow
      return $false
    }
  }
  return $true
}

function New-Link($src, $dst, $isDir) {
  if ($isDir) {
    # Use junction for directories on Windows to avoid symlink privilege requirements.
    New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
    return
  }

  # Developer Mode 無効 + 非管理者で SymbolicLink を作ると、`l` フラグだけ立った
  # 解決不能な reparse point が残ることがある (実害: os.Stat で Access denied)。
  # 作成直後に LinkType/Target が解決できなければ巻き戻し、HardLink → Copy の順で再試行する。
  try {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
    $created = Get-Item -LiteralPath $dst -Force
    if (-not $created.LinkType -or -not $created.Target) {
      Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue
      throw "SymbolicLink created but unresolvable"
    }
    return
  } catch {
    Write-Host "SymbolicLink failed ($($_.Exception.Message)), trying HardLink: $dst" -ForegroundColor Yellow
  }

  try {
    New-Item -ItemType HardLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
    return
  } catch {
    Write-Host "HardLink failed ($($_.Exception.Message)), falling back to Copy: $dst" -ForegroundColor Yellow
  }

  Copy-Item -LiteralPath $src -Destination $dst -Force
}

foreach ($entry in $targets) {
  $src = Join-Path $repo $entry.Src
  if (-not (Test-Path $src)) {
    Write-Host "Skip missing source: $src"
    continue
  }

  # Dst が絶対パスならそのまま、相対パスなら $homeDir 基準
  if ([System.IO.Path]::IsPathRooted($entry.Dst)) {
    $dst = $entry.Dst
  } else {
    $dst = Join-Path $homeDir $entry.Dst
  }

  $dstParent = Split-Path -Parent $dst
  if (-not (Test-Path $dstParent)) {
    New-Item -ItemType Directory -Path $dstParent -Force | Out-Null
  }

  if (-not (Remove-ExistingPath -path $dst)) {
    continue
  }

  $srcItem = Get-Item $src -Force
  New-Link -src $src -dst $dst -isDir $srcItem.PSIsContainer
  Write-Host "Linked: $dst -> $src"
}

# PowerShell profile: modules/ をjunctionでリンクし、プロファイルは最適化版を生成
$profileSrc = Join-Path $repo ".config/powershell"
$documentsDir = [Environment]::GetFolderPath("MyDocuments")
$profileDst = Join-Path $documentsDir "PowerShell"
if (Test-Path -LiteralPath $profileSrc) {
  # 旧setupのディレクトリjunction等を除去してからクリーンに再構築
  Remove-ExistingPath -path $profileDst | Out-Null
  New-Item -ItemType Directory -Path $profileDst -Force | Out-Null

  # modules/ ディレクトリをjunctionでリンク（Terminal-Icons等が参照可能になる）
  $modulesSrc = Join-Path $profileSrc "modules"
  $modulesDst = Join-Path $profileDst "modules"
  if (Test-Path -LiteralPath $modulesSrc) {
    New-Link -src $modulesSrc -dst $modulesDst -isDir $true
    Write-Host "Linked: $modulesDst -> $modulesSrc"
  }

  # conf.d をインライン展開した最適化プロファイルを $PROFILE に書き出す
  $optimScript = Join-Path $binDir "optim_pwsh_profile.ps1"
  $profileOut = Join-Path $profileDst "Microsoft.PowerShell_profile.ps1"
  & $optimScript -SourcePath (Join-Path $profileSrc "Microsoft.PowerShell_profile.ps1") -OutputPath $profileOut
} else {
  Write-Host "Skip missing PowerShell profile source: $profileSrc"
}

# Git hooks: core.hooksPath で参照するディレクトリにリンク
$hooksSrc = Join-Path $repo ".git_template/hooks"
if (Test-Path -LiteralPath $hooksSrc) {
  $hooksDst = Join-Path $homeDir ".git_template/hooks"
  if (-not (Remove-ExistingPath -path $hooksDst)) {
    Write-Host "Warning: Could not update hooks directory" -ForegroundColor Yellow
  } else {
    New-Link -src $hooksSrc -dst $hooksDst -isDir $true
    Write-Host "Linked: $hooksDst -> $hooksSrc"
  }
}

Write-Host "Git template setup completed."

# snoretoast: Windows toast notification CLI (node-notifier にバンドルされたビルドを取得)
$snoretoastDst = Join-Path $binDir "snoretoast.exe"
if (-not (Test-Path -LiteralPath $snoretoastDst)) {
  Write-Host "Installing snoretoast..."
  $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "snoretoast-install"
  try {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    Push-Location $tmpDir
    & npm pack node-notifier --silent 2>$null
    $tgz = Get-ChildItem "node-notifier-*.tgz" | Select-Object -First 1
    tar -xzf $tgz.Name
    Copy-Item "package/vendor/snoreToast/snoretoast-x64.exe" $snoretoastDst
    Pop-Location
    Write-Host "Installed: $snoretoastDst"
  } catch {
    Write-Host "Warning: Failed to install snoretoast: $_" -ForegroundColor Yellow
  } finally {
    if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue }
  }
}

# Ensure dotfiles .bin is available from PATH in all shells.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathItems = @()
if (-not [string]::IsNullOrWhiteSpace($userPath)) {
  $pathItems = $userPath -split ";"
}

if ($pathItems -notcontains $binDir) {
  if ([string]::IsNullOrWhiteSpace($userPath)) {
    $newUserPath = $binDir
  } else {
    $newUserPath = "$userPath;$binDir"
  }
  [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
  $env:Path = "$env:Path;$binDir"
  Write-Host "Added to user PATH: $binDir"
} else {
  Write-Host "Already in user PATH: $binDir"
}

# mise trust & install（未実行の場合のみ）
if (Get-Command "mise" -ErrorAction SilentlyContinue) {
  $miseConfig = Join-Path $repo "mise.toml"
  if (Test-Path $miseConfig) {
    Write-Host "`n=== mise setup ===" -ForegroundColor White
    mise trust $miseConfig
    mise install
  }
} else {
  Write-Host "mise が見つかりません。install_deps.ps1 を先に実行してください。" -ForegroundColor Yellow
}

Write-Host "Windows setup completed." -ForegroundColor Green
& pwsh
