param(
  [Parameter(Mandatory = $true)]
  [string]$Kind
)

$ErrorActionPreference = "Continue"

# Claude Code 本体が kind を小文字で渡してくるケースがあるため正規化する
# (ccwin send の ValidKinds は大文字 Stop/Notification/SubagentStop 等を期待)
$Kind = switch ($Kind.ToLower()) {
  'stop'           { 'Stop' }
  'notification'   { 'Notification' }
  'subagentstop'   { 'SubagentStop' }
  'idle'           { 'Idle' }
  'processstarted' { 'ProcessStarted' }
  'processstopped' { 'ProcessStopped' }
  'pretooluse'     { 'PreToolUse' }
  default          { $Kind }
}

# dev ビルド (リポジトリ内 bin/) を優先しつつ、なければ scoop インストール版に fallback
$projectDir = Join-Path $env:USERPROFILE "Project\github.com\t4ko0522\ccwin-notify"
$devCandidates = @(
  (Join-Path $projectDir "bin\ccwin.exe"),
  (Join-Path $projectDir "ccwin.exe"),
  (Join-Path $projectDir "ccwin-dev.exe")
)
$ccwin = $null
foreach ($c in $devCandidates) {
  if (Test-Path -LiteralPath $c) { $ccwin = $c; break }
}
if (-not $ccwin) {
  $ccwin = Join-Path $env:USERPROFILE "scoop\apps\ccwin\current\ccwin.exe"
  if (-not (Test-Path -LiteralPath $ccwin)) {
    $ccwin = "ccwin.exe"
  }
}

$stdin = [Console]::In.ReadToEnd()
$stdin | & $ccwin send --kind $Kind --stdin 2>&1 | Out-Null
