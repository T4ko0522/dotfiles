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
        $size = if ($isDir) { '-' } else {
            $s = $item.Length
            if ($s -ge 1GB) { '{0:F1}G' -f ($s / 1GB) }
            elseif ($s -ge 1MB) { '{0:F1}M' -f ($s / 1MB) }
            elseif ($s -ge 1KB) { '{0:F1}K' -f ($s / 1KB) }
            else { '{0}B' -f $s }
        }
        $owner = try { ((Get-Acl $item.FullName).Owner -split '\\')[-1] } catch { '-' }
        [PSCustomObject]@{
            Item    = $item
            IsDir   = $isDir
            RawPerm = $rawPerm
            Size    = $size
            Owner   = $owner
        }
    }

    # カラム幅を計算
    $sizeWidth = ($rows | ForEach-Object { $_.Size.Length } | Measure-Object -Maximum).Maximum
    $ownerWidth = ($rows | ForEach-Object { $_.Owner.Length } | Measure-Object -Maximum).Maximum

    # ヘッダー
    $hPerm  = 'Permission'.PadRight(10)
    $hSize  = 'Size'.PadLeft($sizeWidth)
    $hOwner = 'User'.PadRight($ownerWidth)
    $hDate  = 'Date Modified'.PadRight(16)
    $hName  = 'Name'
    "${e}[1m${hPerm}  ${hSize}  ${hOwner}  ${hDate}  ${hName}${e}[0m"

    foreach ($row in $rows) {
        # Permission（Blue→Cyan→Green→Yellow グラデーション）
        $gradColors = @(
            @(70,130,255), @(35,175,237), @(0,220,220), @(27,220,180),
            @(53,220,140), @(80,220,100), @(133,220,87), @(187,220,73),
            @(213,220,67), @(240,220,60)
        )
        $perm = -join (0..9 | ForEach-Object {
            $c = $row.RawPerm[$_]; $rgb = $gradColors[$_]
            if ($c -eq '-') { "${e}[90m-${e}[0m" }
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

        $nameColor = if ($row.IsDir) { "${e}[1;34m" } elseif ($row.Item.Extension -match '\.(exe|cmd|bat|ps1|sh)$') { "${e}[1;32m" } else { "${e}[0m" }

        "${perm}  ${e}[1;32m${size}${e}[0m  ${e}[38;2;224;102;255m${owner}${e}[0m  ${e}[36m${date}${e}[0m  ${nameColor}${icon}$($row.Item.Name)${e}[0m"
    }
}
function la { ls -a @args }
function ll { ls @args }
