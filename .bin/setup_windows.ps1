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
  @{ Src = ".config/yasb";          Dst = ".config/yasb" },
  @{ Src = ".config/whkdrc";              Dst = ".config/whkdrc" },
  @{ Src = ".config/applications.json";    Dst = "applications.json" },
  @{ Src = ".config/komorebi.json";        Dst = "komorebi.json" },
  @{ Src = ".config/komorebi.bar.json";    Dst = "komorebi.bar.json" },
  @{ Src = ".config/komorebi_state_check.txt"; Dst = "komorebi_state_check.txt" }
)

function Remove-ExistingPath($path) {
  if (-not (Test-Path -LiteralPath $path)) {
    return $true
  }

  # Replace any existing path (file/dir/link) so setup always converges
  try {
    Remove-Item -LiteralPath $path -Force -Recurse -ErrorAction Stop
  } catch {
    # ロック中のファイルがある場合、個別に削除を試みる（ログファイル等をスキップ）
    if (Test-Path -LiteralPath $path -PathType Container) {
      Get-ChildItem -LiteralPath $path -Recurse -Force | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
        try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch {
          Write-Host "Warning: Skipped locked file: $($_.FullName)" -ForegroundColor Yellow
        }
      }
      try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop } catch {
        Write-Host "Warning: Could not remove directory (locked files remain): $path" -ForegroundColor Yellow
        return $false
      }
    } else {
      Write-Host "Warning: Could not remove locked file: $path" -ForegroundColor Yellow
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

  try {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
  } catch {
    Write-Host "SymbolicLink failed, fallback to HardLink: $dst"
    New-Item -ItemType HardLink -Path $dst -Target $src | Out-Null
  }
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

# PowerShell profile: リポジトリのプロファイルをクリーンして $PROFILE のコピー先に書き出す（リンクしない）。
$profileSrc = Join-Path $repo ".config/powershell/Microsoft.PowerShell_profile.ps1"
$documentsDir = [Environment]::GetFolderPath("MyDocuments")
$profileDst = Join-Path $documentsDir "PowerShell\\Microsoft.PowerShell_profile.ps1"
if (Test-Path -LiteralPath $profileSrc) {
  $profileParent = Split-Path -Parent $profileDst
  if (-not (Test-Path -LiteralPath $profileParent)) {
    New-Item -ItemType Directory -Path $profileParent -Force | Out-Null
  }
  Remove-ExistingPath -path $profileDst | Out-Null
  & (Join-Path $binDir "optim_pwsh_profile.ps1") -SourcePath $profileSrc -OutputPath $profileDst
} else {
  Write-Host "Skip missing PowerShell profile source: $profileSrc"
}

# Ensure git-init template includes .cursorrules so new repos get it automatically.
$cursorRulesSrc = Join-Path $repo ".cursorrules"
if (Test-Path -LiteralPath $cursorRulesSrc) {
  $gitTemplateDir = Join-Path $homeDir ".git_template/git-secrets"
  if (-not (Test-Path -LiteralPath $gitTemplateDir)) {
    New-Item -ItemType Directory -Path $gitTemplateDir -Force | Out-Null
  }

  $cursorRulesDst = Join-Path $gitTemplateDir ".cursorrules"
  Copy-Item -LiteralPath $cursorRulesSrc -Destination $cursorRulesDst -Force
  Write-Host "Installed git template file: $cursorRulesDst"
} else {
  Write-Host "Skip missing source: $cursorRulesSrc"
}

Write-Host "Git template setup completed."

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

# Ensure BurntToast module is available for Claude Code notification hooks.
if (-not (Get-Module -ListAvailable -Name BurntToast)) {
  Write-Host "Installing BurntToast module for Claude Code notifications..."
  Install-Module -Name BurntToast -Scope CurrentUser -Force -SkipPublisherCheck
  Write-Host "BurntToast module installed."
} else {
  Write-Host "BurntToast module already installed."
}

Write-Host "Windows setup completed."
