# Claude Code Notification Hook
# Reads JSON from stdin, shows Windows toast notification + plays custom sound.
#
# Usage:
#   echo '{"notification_type":"permission_prompt"}' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File claude_notify.ps1
#   echo '{"notification_type":"permission_prompt"}' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File claude_notify.ps1 -SoundPath "C:\path\to\sound.wav"
param(
  [string]$SoundPath = (Join-Path $env:USERPROFILE ".claude/sounds.mp3"),
  [string]$AppLogo   = (Join-Path $PSScriptRoot "claude-icon.svg")
)

$json = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($json)) { exit 0 }

try {
  $data = $json | ConvertFrom-Json
} catch {
  exit 1
}

$type = $data.notification_type
if ($type -notin @("permission_prompt", "idle_prompt")) { exit 0 }

switch ($type) {
  "permission_prompt" {
    $title = "Claude Code - Permission Required"
    $message = "Claude is waiting for your approval."
  }
  "idle_prompt" {
    $title = "Claude Code - Task Complete"
    $message = "Claude has finished and is waiting for input."
  }
}

# --- Sound ---
if (-not [string]::IsNullOrWhiteSpace($SoundPath) -and (Test-Path -LiteralPath $SoundPath)) {
  try {
    if ([System.IO.Path]::GetExtension($SoundPath).ToLower() -eq '.wav') {
      $player = New-Object System.Media.SoundPlayer($SoundPath)
      $player.PlaySync()
      $player.Dispose()
    } else {
      Add-Type -AssemblyName PresentationCore
      $player = New-Object System.Windows.Media.MediaPlayer
      $player.Open([Uri]::new($SoundPath))
      Start-Sleep -Milliseconds 100
      $player.Play()
      Start-Sleep -Milliseconds 500
      $player.Close()
    }
  } catch {}
}

# --- Toast Notification ---
$usedBurntToast = $false
if (Get-Module -ListAvailable -Name BurntToast) {
  try {
    Import-Module BurntToast -ErrorAction Stop
    $toastParams = @{ Text = $title, $message; Silent = $true }
    if (-not [string]::IsNullOrWhiteSpace($AppLogo) -and (Test-Path -LiteralPath $AppLogo)) {
      $toastParams.AppLogo = $AppLogo
    }
    New-BurntToastNotification @toastParams
    $usedBurntToast = $true
  } catch {}
}

if (-not $usedBurntToast) {
  # Fallback: balloon tip via NotifyIcon
  try {
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.Visible = $true
    $notify.ShowBalloonTip(5000, $title, $message, [System.Windows.Forms.ToolTipIcon]::Info)
    Start-Sleep -Milliseconds 500
    $notify.Dispose()
  } catch {}
}
