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
