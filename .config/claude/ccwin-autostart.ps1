# Claude Code SessionStart Hook
# ccwin daemon が起動していなければバックグラウンドで立ち上げる。

$ErrorActionPreference = "SilentlyContinue"

$portfile = Join-Path $env:APPDATA "ccwin-notify\daemon.port"
if (Test-Path -LiteralPath $portfile) {
  try {
    $info = Get-Content -LiteralPath $portfile -Raw | ConvertFrom-Json
    if ($info.pid -and (Get-Process -Id $info.pid -ErrorAction SilentlyContinue)) {
      exit 0
    }
    Remove-Item -LiteralPath $portfile -Force -ErrorAction SilentlyContinue
  } catch {
    Remove-Item -LiteralPath $portfile -Force -ErrorAction SilentlyContinue
  }
}

# dev ビルドを優先しつつ scoop -> PATH の順で fallback (ccwin-hook.ps1 と同じ解決順)
$devCandidates = @(
  "C:\Users\takow\Project\github.com\t4ko0522\ccwin-notify\bin\ccwin.exe",
  "C:\Users\takow\Project\github.com\t4ko0522\ccwin-notify\ccwin.exe",
  "C:\Users\takow\Project\github.com\t4ko0522\ccwin-notify\ccwin-dev.exe"
)
$exe = $null
foreach ($c in $devCandidates) {
  if (Test-Path -LiteralPath $c) { $exe = $c; break }
}
if (-not $exe) {
  $scoop = Join-Path $env:USERPROFILE "scoop\apps\ccwin\current\ccwin.exe"
  if (Test-Path -LiteralPath $scoop) { $exe = $scoop } else { $exe = "ccwin" }
}

Start-Process -FilePath $exe -ArgumentList "daemon" -WindowStyle Hidden
