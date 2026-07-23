$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$homeDir = [Environment]::GetFolderPath("UserProfile")
$roamingDir = [Environment]::GetFolderPath("ApplicationData")
$scriptsDir = Join-Path $repo "scripts"

if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
  throw "chezmoi が見つかりません。bootstrap.ps1 を先に実行してください。"
}

& chezmoi --source $repo init --promptChoice "Environment profile=windows"
if ($LASTEXITCODE -ne 0) {
  throw "chezmoi init failed (exit=$LASTEXITCODE)"
}

$chezmoiProfile = (& chezmoi --source $repo execute-template "{{ .profile }}").Trim()
if ($chezmoiProfile -ne "windows") {
  throw "chezmoi profile must be windows (actual=$chezmoiProfile)"
}

& chezmoi --source $repo apply
if ($LASTEXITCODE -ne 0) {
  throw "chezmoi apply failed (exit=$LASTEXITCODE)"
}

# Src: repo からの相対パス
# Dst: 相対パス → $homeDir 基準、絶対パス → そのまま使用
$targets = @(
  @{ Src = ".gitconfig";            Dst = ".gitconfig" },
  # Claude: 共通ファイルは個別リンク。settings.json は base+hooks を後段でマージ生成する。
  @{ Src = "dot_config/shared/claude/CLAUDE.md";       Dst = ".claude/CLAUDE.md" },
  @{ Src = "dot_config/shared/claude/agents";          Dst = ".claude/agents" },
  @{ Src = "dot_config/shared/claude/skills";          Dst = ".claude/skills" },
  @{ Src = "dot_config/shared/claude/statusline.sh";   Dst = ".claude/statusline.sh" },
  @{ Src = "dot_config/shared/claude/claude-icon.svg"; Dst = ".claude/claude-icon.svg" },
  @{ Src = "dot_config/windows/claude/ccwin-hook.ps1"; Dst = ".claude/ccwin-hook.ps1" },
  @{ Src = "dot_config/shared/codex";         Dst = ".codex" },
  @{ Src = "dot_config/shared/lazygit";       Dst = ".config/lazygit" },
  @{ Src = "dot_config/shared/mise";          Dst = ".config/mise" },
  @{ Src = "dot_config/shared/vim";           Dst = ".config/vim" },
  @{ Src = "dot_config/shared/wezterm";       Dst = ".config/wezterm" },
  @{ Src = "dot_config/shared/yazi";          Dst = (Join-Path $roamingDir "yazi\config") },
  @{ Src = "dot_config/shared/starship.toml"; Dst = ".config/starship.toml" },
  @{ Src = "dot_config/shared/fastfetch";     Dst = ".config/fastfetch" },
  @{ Src = "dot_config/windows/ccwin-notify"; Dst = ".config/ccwin-notify" },
  @{ Src = "dot_config/shared/vscode/settings.json";    Dst = (Join-Path $roamingDir "Code\User\settings.json") },
  @{ Src = "dot_config/shared/vscode/keybindings.json"; Dst = (Join-Path $roamingDir "Code\User\keybindings.json") },
  @{ Src = "dot_config/shared/vscode/snippets";         Dst = (Join-Path $roamingDir "Code\User\snippets") },
  @{ Src = "dot_config/shared/zed/settings.json";       Dst = (Join-Path $roamingDir "Zed\settings.json") },
  @{ Src = "dot_config/shared/zed/keymap.json";         Dst = (Join-Path $roamingDir "Zed\keymap.json") },
  @{ Src = "dot_config/shared/zed/tasks.json";          Dst = (Join-Path $roamingDir "Zed\tasks.json") }
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

# 旧 setup は .claude をディレクトリ junction にしていた。ファイル単位リンクへ移行するため、
# reparse point (junction/symlink) なら先に除去する。junction 内のファイルを個別 Remove すると
# リンク先 (repo) を破壊するため、この事前除去が必須。
$claudeHome = Join-Path $homeDir ".claude"
$claudeItem = Get-Item -LiteralPath $claudeHome -Force -ErrorAction SilentlyContinue
if ($claudeItem -and ($claudeItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
  Remove-ExistingPath -path $claudeHome | Out-Null
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

# Claude settings.json: 共通 base に Windows 固有 hooks をマージして生成する。
# (Linux/Nix 側は base をそのまま生成。hooks は Windows 専用のため setup でのみ合成)
$claudeBase  = Join-Path $repo "dot_config/shared/claude/settings.json"
$claudeHooks = Join-Path $repo "dot_config/windows/claude/settings.hooks.json"
$claudeDst   = Join-Path $homeDir ".claude/settings.json"
if ((Test-Path $claudeBase) -and (Test-Path $claudeHooks)) {
  Remove-ExistingPath -path $claudeDst | Out-Null
  $claudeParent = Split-Path -Parent $claudeDst
  if (-not (Test-Path $claudeParent)) {
    New-Item -ItemType Directory -Path $claudeParent -Force | Out-Null
  }
  $base  = Get-Content -LiteralPath $claudeBase  -Raw | ConvertFrom-Json
  $hooks = Get-Content -LiteralPath $claudeHooks -Raw | ConvertFrom-Json
  $base | Add-Member -NotePropertyName hooks -NotePropertyValue $hooks.hooks -Force
  $base | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $claudeDst -Encoding UTF8
  Write-Host "Generated: $claudeDst (shared base + windows hooks)"
} else {
  Write-Host "Skip Claude settings merge: missing base or hooks fragment" -ForegroundColor Yellow
}

# PowerShell profile: modules/ をjunctionでリンクし、プロファイルは最適化版を生成
$profileSrc = Join-Path $repo "dot_config/windows/powershell"
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
  $optimScript = Join-Path $scriptsDir "optim_pwsh_profile.ps1"
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

# Ensure dotfiles scripts dir is available from PATH in all shells.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathItems = @()
if (-not [string]::IsNullOrWhiteSpace($userPath)) {
  $pathItems = $userPath -split ";"
}

if ($pathItems -notcontains $scriptsDir) {
  if ([string]::IsNullOrWhiteSpace($userPath)) {
    $newUserPath = $scriptsDir
  } else {
    $newUserPath = "$userPath;$scriptsDir"
  }
  [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
  $env:Path = "$env:Path;$scriptsDir"
  Write-Host "Added to user PATH: $scriptsDir"
} else {
  Write-Host "Already in user PATH: $scriptsDir"
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
  Write-Host "mise が見つかりません。bootstrap.ps1 を先に実行してください。" -ForegroundColor Yellow
}

Write-Host "Windows setup completed." -ForegroundColor Green
& pwsh
