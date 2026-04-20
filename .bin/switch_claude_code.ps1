[CmdletBinding()]
param(
    [ValidateSet("native", "npm", "status")]
    [string]$Mode = "status",

    [string]$LauncherRoot,
    [string]$NativePath,
    [string]$MisePath,

    [switch]$SkipPathUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HomeDir {
    if (-not [string]::IsNullOrWhiteSpace($env:HOME)) {
        return $env:HOME
    }

    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        return $env:USERPROFILE
    }

    throw "HOME and USERPROFILE are both unavailable."
}

function Get-MiseDataDir {
    if (-not [string]::IsNullOrWhiteSpace($env:MISE_DATA_DIR)) {
        return $env:MISE_DATA_DIR
    }

    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        return (Join-Path $env:LOCALAPPDATA "mise")
    }

    throw "LOCALAPPDATA is unavailable."
}

function Convert-ToForwardSlashPath {
    param([Parameter(Mandatory)][string]$Path)

    return ($Path -replace "\\", "/")
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Normalize-PathEntry {
    param([Parameter(Mandatory)][string]$Path)

    return $Path.Trim().TrimEnd("\").ToLowerInvariant()
}

function Prepend-PathEntry {
    param(
        [string[]]$Entries,
        [Parameter(Mandatory)][string]$Entry
    )

    $normalizedEntry = Normalize-PathEntry -Path $Entry
    $filteredEntries = @()

    foreach ($item in ($Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        if ((Normalize-PathEntry -Path $item) -ne $normalizedEntry) {
            $filteredEntries += $item
        }
    }

    return @($Entry) + $filteredEntries
}

function Ensure-UserPathPrefix {
    param([Parameter(Mandatory)][string]$Entry)

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userEntries = if ([string]::IsNullOrWhiteSpace($userPath)) {
        @()
    } else {
        @($userPath -split ";")
    }

    $newUserEntries = Prepend-PathEntry -Entries $userEntries -Entry $Entry
    $newUserPath = ($newUserEntries -join ";")

    if ($newUserPath -ne $userPath) {
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Output "Updated user PATH: $Entry"
    } else {
        Write-Output "User PATH already prioritized: $Entry"
    }

    $processEntries = if ([string]::IsNullOrWhiteSpace($env:Path)) {
        @()
    } else {
        @($env:Path -split ";")
    }

    $env:Path = (Prepend-PathEntry -Entries $processEntries -Entry $Entry) -join ";"
}

function Resolve-MisePath {
    param([string]$ExplicitPath)

    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $candidates += $ExplicitPath
    }

    $command = Get-Command mise -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
        $candidates += $command.Source
    }

    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidates += (Join-Path $env:LOCALAPPDATA "mise\bin\mise.exe")
    }

    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $candidates += (Join-Path $env:USERPROFILE "scoop\apps\mise\current\bin\mise.exe")
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "mise.exe was not found. Install mise or pass -MisePath."
}

function Get-NpmClaudeShimCandidates {
    $shimsDir = Join-Path (Get-MiseDataDir) "shims"
    return @(
        (Join-Path $shimsDir "claude.exe"),
        (Join-Path $shimsDir "claude.cmd"),
        (Join-Path $shimsDir "claude")
    )
}

function Test-NpmClaudeInstalled {
    foreach ($candidate in (Get-NpmClaudeShimCandidates)) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $true
        }
    }

    return $false
}

function Write-CmdLauncher {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Mode,
        [string]$NativePath,
        [string]$MisePath
    )

    $body = switch ($Mode) {
        "native" {
@"
@echo off
setlocal
"$NativePath" %*
exit /b %ERRORLEVEL%
"@
        }
        "npm" {
@"
@echo off
setlocal
"$MisePath" x -- claude %*
exit /b %ERRORLEVEL%
"@
        }
        default {
            throw "Unsupported mode: $Mode"
        }
    }

    Set-Content -LiteralPath $Path -Value $body -Encoding ASCII
}

function Write-BashLauncher {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Mode,
        [string]$NativePath,
        [string]$MisePath
    )

    $body = switch ($Mode) {
        "native" {
            $nativeTarget = Convert-ToForwardSlashPath -Path $NativePath
            @(
                "#!/usr/bin/env bash"
                "set -euo pipefail"
                ("exec '{0}' ""`$@""" -f $nativeTarget)
            ) -join "`n"
        }
        "npm" {
            $miseTarget = Convert-ToForwardSlashPath -Path $MisePath
            @(
                "#!/usr/bin/env bash"
                "set -euo pipefail"
                ("exec '{0}' x -- claude ""`$@""" -f $miseTarget)
            ) -join "`n"
        }
        default {
            throw "Unsupported mode: $Mode"
        }
    }

    Set-Content -LiteralPath $Path -Value $body -Encoding ASCII
}

function Write-StateFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)][string]$LauncherRoot,
        [Parameter(Mandatory)][string]$LauncherBin,
        [Parameter(Mandatory)][string]$NativePath,
        [string]$MisePath
    )

    $state = [PSCustomObject]@{
        mode = $Mode
        updatedAt = (Get-Date).ToString("o")
        launcherRoot = $LauncherRoot
        launcherBin = $LauncherBin
        nativePath = $NativePath
        misePath = $MisePath
        npmShimCandidates = @(Get-NpmClaudeShimCandidates)
    }

    $state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Read-StateFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return (Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json)
}

function Show-Status {
    param(
        [Parameter(Mandatory)][string]$StatePath,
        [Parameter(Mandatory)][string]$LauncherBin,
        [Parameter(Mandatory)][string]$NativePath,
        [string]$MisePath
    )

    $state = Read-StateFile -Path $StatePath

    if ($null -eq $state) {
        Write-Output "Mode: unconfigured"
        return
    }

    Write-Output "Mode: $($state.mode)"
}

$homeDir = Get-HomeDir

if ([string]::IsNullOrWhiteSpace($LauncherRoot)) {
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw "LOCALAPPDATA is unavailable."
    }

    $LauncherRoot = Join-Path $env:LOCALAPPDATA "claude-code-launcher"
}

if ([string]::IsNullOrWhiteSpace($NativePath)) {
    $NativePath = Join-Path $homeDir ".local\bin\claude.exe"
}

$launcherBin = Join-Path $LauncherRoot "bin"
$statePath = Join-Path $LauncherRoot "state.json"

switch ($Mode) {
    "status" {
        $statusMisePath = $null
        try {
            $statusMisePath = Resolve-MisePath -ExplicitPath $MisePath
        } catch {
        }

        Show-Status -StatePath $statePath -LauncherBin $launcherBin -NativePath $NativePath -MisePath $statusMisePath
        return
    }
    "native" {
        if (-not (Test-Path -LiteralPath $NativePath -PathType Leaf)) {
            throw "Native Claude Code was not found: $NativePath"
        }
    }
    "npm" {
        $MisePath = Resolve-MisePath -ExplicitPath $MisePath

        if (-not (Test-NpmClaudeInstalled)) {
            throw "mise-managed Claude Code was not found. Add npm:@anthropic-ai/claude-code to mise and run `mise install`."
        }
    }
}

Ensure-Directory -Path $LauncherRoot
Ensure-Directory -Path $launcherBin

$cmdLauncherPath = Join-Path $launcherBin "claude.cmd"
$bashLauncherPath = Join-Path $launcherBin "claude"

Write-CmdLauncher -Path $cmdLauncherPath -Mode $Mode -NativePath $NativePath -MisePath $MisePath
Write-BashLauncher -Path $bashLauncherPath -Mode $Mode -NativePath $NativePath -MisePath $MisePath
Write-StateFile -Path $statePath -Mode $Mode -LauncherRoot $LauncherRoot -LauncherBin $launcherBin -NativePath $NativePath -MisePath $MisePath

if ($SkipPathUpdate) {
    Write-Output "Skipped user PATH update."
} else {
    Ensure-UserPathPrefix -Entry $launcherBin
}

Write-Output "Switched Claude Code launcher to: $Mode"
Write-Output "Launcher dir: $launcherBin"

if ($Mode -eq "npm") {
    Write-Output "Target: $MisePath x -- claude"
} else {
    Write-Output "Target: $NativePath"
}

Write-Output "Open a new shell to apply the updated user PATH everywhere."
