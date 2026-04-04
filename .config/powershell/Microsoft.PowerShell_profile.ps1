# ============================================================================
# PowerShell プロファイル
# ============================================================================

# ----------------------------------------------------------------------------
# モジュールのインポート
# install: https://github.com/devblackops/Terminal-Icons
# ----------------------------------------------------------------------------
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# ----------------------------------------------------------------------------
# https://github.com/antfu-collective/ni とNew-Itemの競合を無効化
# ----------------------------------------------------------------------------
Remove-Item Alias:ni -Force -ErrorAction Ignore

# ----------------------------------------------------------------------------
# yasb 自動起動
# ----------------------------------------------------------------------------
if (-not (Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
    Start-Process yasb -WindowStyle Hidden
}

# ----------------------------------------------------------------------------
# PSReadLine設定（入力補完・予測入力）
# ----------------------------------------------------------------------------

Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -MaximumHistoryCount 16384
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -Colors @{
    Command              = "Green"
    Error                = "Red"
    InlinePrediction      = "Magenta"
    ListPrediction        = "Magenta"
    ListPredictionSelected = "#e066ff"
}
# ----------------------------------------------------------------------------
# mise 初期化
# ----------------------------------------------------------------------------
if (Get-Command mise -ErrorAction SilentlyContinue) {
    $pathSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $env:PATH -split ';' | ForEach-Object { [void]$pathSet.Add($_) }

    $miseShims = Join-Path $env:LOCALAPPDATA "mise\shims"
    if ($miseShims -and (Test-Path $miseShims) -and $pathSet.Add($miseShims)) {
        $env:PATH = "$miseShims;$env:PATH"
    }

    # mise bin-paths + installs フォールバックを統合
    $misePaths = [System.Collections.Generic.List[string]]::new()
    foreach ($p in (& mise bin-paths 2>$null)) {
        if ($p -and (Test-Path $p)) { $misePaths.Add($p) }
    }

    $installsRoot = Join-Path $env:LOCALAPPDATA "mise\installs"
    if (Test-Path $installsRoot) {
        foreach ($toolDir in Get-ChildItem $installsRoot -Directory -ErrorAction SilentlyContinue) {
            $latest = Get-ChildItem $toolDir.FullName -Directory -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending | Select-Object -First 1
            if (-not $latest) { continue }
            foreach ($dir in @($latest.FullName) + @(Get-ChildItem $latest.FullName -Directory -ErrorAction SilentlyContinue).FullName) {
                if (-not $dir) { continue }
                $hasExe = Get-ChildItem $dir -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Extension -in '.exe','.cmd','.bat','.ps1' } |
                    Select-Object -First 1
                if ($hasExe) { $misePaths.Add($dir) }
            }
        }
    }

    # 逆順で PATH 先頭に追加（後に追加したものほど優先）
    $misePaths.Reverse()
    foreach ($p in $misePaths) {
        if ($pathSet.Add($p)) {
            $env:PATH = "$p;$env:PATH"
        }
    }

    Invoke-Expression ((& mise activate pwsh) | Out-String)
}

# ----------------------------------------------------------------------------
# Starship プロンプト初期化
# install: mise install starship
# ----------------------------------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# ----------------------------------------------------------------------------
# カスタムエイリアス・関数
# ----------------------------------------------------------------------------
Set-Alias wh where.exe
Set-Alias vi nvim
Set-Alias open explorer

# 上位ディレクトリへ一気に移動（... = 2階上, .... = 3階上, ..... = 4階上）
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# git init 後に .cursorrules を自動配置
function git {
    if ($args.Count -ge 1 -and $args[0] -eq "init") {
        git.exe @args
        $src = Join-Path $env:USERPROFILE ".git_template/git-secrets/.cursorrules"
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination ".cursorrules" -Force
        }
    } else {
        git.exe @args
    }
}

# %USERNAME%/Projectに移動するエイリアス
function cdp {
    Set-Location "$env:USERPROFILE\Project"
}

# %USERNAME%/Project/github.com/T4ko0522に移動するエイリアス
function cdtako {
    Set-Location "$env:USERPROFILE\Project\github.com\T4ko0522"
}

# Ctrl+F: ホーム以下のディレクトリをfzfで検索してcd
Set-PSReadLineKeyHandler -Key Ctrl+f -ScriptBlock {
    $dir = fd --type d --hidden --exclude .git --base-directory $env:USERPROFILE | fzf --reverse --border --height=40%
    if ($dir) {
        $fullPath = Join-Path $env:USERPROFILE $dir
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd '$fullPath'")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

# ghqとpecoを使用してリポジトリに移動する関数
# install: https://github.com/x-motemen/ghq
# install: https://github.com/peco/peco
function ghcd() {
    Set-Location "$(ghq root)/$(ghq list | peco)"
}

# yaziで移動したディレクトリにシェルもcdするラッパー関数
function yz {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -ErrorAction SilentlyContinue
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location -Path $cwd
    }
    Remove-Item -Path $tmp -ErrorAction SilentlyContinue
}