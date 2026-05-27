Set-Alias wh where.exe
Set-Alias vi nvim
Set-Alias open explorer

# Unix風 ls（Permission, Size, User, Date Modified, Name）+ 色 + アイコン
Remove-Item Alias:ls -Force -ErrorAction Ignore

# Terminal-Icons グリフテーブルの遅延ロード（OnIdle未完了時のフォールバック）
function _ensureLsIcons {
    if ($global:_lsGlyphs) { return }
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    if (Get-Module Terminal-Icons -ErrorAction SilentlyContinue) {
        $global:_lsGlyphs = @{}
        Get-TerminalIconsGlyphs | ForEach-Object { $global:_lsGlyphs[$_.Name] = $_.Value }
        $global:_lsTheme = Get-TerminalIconsTheme
    }
}

# ファイル所有者名を取得（Owner セクションのみ取得 + SID→名前をセッションキャッシュ。Get-Acl 全体取得より約7倍高速）
function _getOwnerName {
    param($item)
    if (-not $global:_lsOwnerCache) { $global:_lsOwnerCache = @{} }
    try {
        $sid = [System.IO.FileSystemAclExtensions]::GetAccessControl($item, [System.Security.AccessControl.AccessControlSections]::Owner).GetOwner([System.Security.Principal.SecurityIdentifier]).Value
        $name = $global:_lsOwnerCache[$sid]
        if (-not $name) {
            $name = (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
            $global:_lsOwnerCache[$sid] = $name
        }
        ($name -split '\\')[-1]
    } catch { '-' }
}

function ls {
    param([switch]$a, [switch]$l)
    _ensureLsIcons
    $path = ($args | Where-Object { $_ -notmatch '^-' } | Select-Object -First 1) ?? '.'
    $items = if ($a) {
        Get-ChildItem -Path $path -Force
    } else {
        Get-ChildItem -Path $path
    }
    $items = @($items | Sort-Object { -not $_.PSIsContainer }, Name)

    if ($items.Count -eq 0) { Write-Host '-'; return }

    $e = [char]0x1b

    # 各アイテムのデータを事前計算
    $rows = foreach ($item in $items) {
        $isDir = $item.PSIsContainer
        $ro = $item.Attributes -band [System.IO.FileAttributes]::ReadOnly
        $rawPerm = if ($isDir) {
            if ($ro) { 'dr-xr-xr-x' } else { 'drwxr-xr-x' }
        } else {
            if ($ro) { '-r--r--r--' } else { '-rw-r--r--' }
        }
        $size = if ($isDir) { ' -- ' } else {
            $s = $item.Length
            if ($s -ge 1GB) { '{0:F1}G' -f ($s / 1GB) }
            elseif ($s -ge 1MB) { '{0:F1}M' -f ($s / 1MB) }
            elseif ($s -ge 1KB) { '{0:F1}K' -f ($s / 1KB) }
            else { '{0}B' -f $s }
        }
        $owner = _getOwnerName $item
        [PSCustomObject]@{
            Item    = $item
            IsDir   = $isDir
            RawPerm = $rawPerm
            Size    = $size
            Owner   = $owner
        }
    }

    # カラム幅を計算（ヘッダーラベル長を最小幅として保証）
    $sizeWidth = [Math]::Max(4, ($rows | ForEach-Object { $_.Size.Length } | Measure-Object -Maximum).Maximum)
    $ownerWidth = [Math]::Max(4, ($rows | ForEach-Object { $_.Owner.Length } | Measure-Object -Maximum).Maximum)

    # ヘッダー
    $hPerm  = 'Permission'.PadRight(10)
    $hSize  = 'Size'.PadLeft($sizeWidth)
    $hOwner = 'User'.PadRight($ownerWidth)
    $hDate  = 'Date Modified'.PadRight(16)
    $hName  = 'Name'
    "${e}[1;38;2;180;190;254m${hPerm}  ${hSize}  ${hOwner}  ${hDate}  ${hName}${e}[0m"

    # Permission の桁ごとグラデーション（Catppuccin Mocha: Lavender→Blue→Sapphire→Sky→Teal→Green→Yellow→Peach→Maroon→Red）。ループ外で1度だけ定義
    $gradColors = @(
        @(180,190,254), @(137,180,250), @(116,199,236), @(137,220,235),
        @(148,226,213), @(166,227,161), @(249,226,175), @(250,179,135),
        @(235,160,172), @(243,139,168)
    )

    foreach ($row in $rows) {
        $perm = -join (0..9 | ForEach-Object {
            $c = $row.RawPerm[$_]; $rgb = $gradColors[$_]
            if ($c -eq '-') { "${e}[38;2;108;112;134m-${e}[0m" }
            else { "${e}[38;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m${c}${e}[0m" }
        })

        $size = $row.Size.PadLeft($sizeWidth)
        $owner = $row.Owner.PadRight($ownerWidth)
        $date = $row.Item.LastWriteTime.ToString('ddd dd MMM HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)

        # Icon (Terminal-Icons)
        $icon = ''
        if ($global:_lsTheme -and $global:_lsGlyphs) {
            $glyphName = $null
            if ($row.IsDir) {
                $glyphName = $global:_lsTheme.Icon.Types.Directories.WellKnown[$row.Item.Name]
                if (-not $glyphName) { $glyphName = 'nf-custom-folder' }
            } else {
                $ext = $row.Item.Extension.ToLower()
                if ($ext) { $glyphName = $global:_lsTheme.Icon.Types.Files[$ext] }
                if (-not $glyphName) { $glyphName = 'nf-fa-file' }
            }
            $g = $global:_lsGlyphs[$glyphName]
            if ($g) { $icon = "$g " }
        }

        # Catppuccin Mocha: Dir=Pink, Exec=Teal, Other=Rosewater（最も明度の高い系統で揃え、bold で前面に）
        $nameColor = if ($row.IsDir) { "${e}[1;38;2;245;194;231m" } elseif ($row.Item.Extension -match '\.(exe|cmd|bat|ps1|sh)$') { "${e}[1;38;2;148;226;213m" } else { "${e}[1;38;2;245;224;220m" }

        "${perm}  ${e}[1;38;2;166;227;161m${size}${e}[0m  ${e}[38;2;203;166;247m${owner}${e}[0m  ${e}[38;2;137;220;235m${date}${e}[0m  ${nameColor}${icon}$($row.Item.Name)${e}[0m"
    }
}
# Unix風 rm（-r, -f, -rf 対応）
Remove-Item Alias:rm -Force -ErrorAction Ignore
function rm {
    # -r/-f を結合フラグ (-rf, -fr) でも分離フラグ (-r -f) でも受け付ける
    $flags = ''
    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($a in $args) {
        if ($a -is [string] -and $a.Length -gt 1 -and $a[0] -eq '-') {
            $flags += $a.Substring(1)
        } else {
            $paths.Add([string]$a)
        }
    }
    $r = $flags.Contains('r')
    $f = $flags.Contains('f')
    if ($paths.Count -eq 0) { Write-Error 'rm: missing operand'; return }
    $params = @{}
    if ($r) { $params['Recurse'] = $true }
    if ($f) { $params['Force'] = $true; $params['ErrorAction'] = 'SilentlyContinue' }
    foreach ($p in $paths) {
        if (-not $f -and -not (Test-Path $p)) {
            Write-Error "rm: cannot remove '$p': No such file or directory"
            continue
        }
        Remove-Item -Path $p -Confirm:(-not $f) @params
    }
}

# Unix風 mkdir（-p 対応、デフォルトで再帰作成）
Remove-Item Alias:mkdir -Force -ErrorAction Ignore
function mkdir {
    param([switch]$p)
    $paths = @($args | Where-Object { $_ -notmatch '^-' })
    if (-not $paths) { Write-Error 'mkdir: missing operand'; return }
    foreach ($d in $paths) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

# Unix風 touch（存在すればタイムスタンプ更新、なければ作成）
function touch {
    $paths = @($args | Where-Object { $_ -notmatch '^-' })
    if (-not $paths) { Write-Error 'touch: missing operand'; return }
    foreach ($p in $paths) {
        if (Test-Path $p) {
            (Get-Item $p).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $p -Force | Out-Null
        }
    }
}

# Unix風 pwd（パス文字列のみ返す、スラッシュ区切り）
Remove-Alias pwd -Force -ErrorAction Ignore
function pwd { ($ExecutionContext.SessionState.Path.CurrentLocation.Path -replace '\\', '/') | Write-Host }

function la { ls -a @args }
function ll { ls @args }

# Claude Code: cc=claude / cc yolo=claude --dangerously-skip-permissions（以降の引数はそのまま委譲）
function cc {
    if ($args.Count -gt 0 -and $args[0] -eq 'yolo') {
        $rest = $args | Select-Object -Skip 1
        claude --dangerously-skip-permissions @rest
    } else {
        claude @args
    }
}
