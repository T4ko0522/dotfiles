# ============================================================================
# PowerShell プロファイル
# ============================================================================

$modulesDir = Join-Path $PSScriptRoot "conf.d"

. "$modulesDir\startup.ps1"
. "$modulesDir\mise.ps1"
. "$modulesDir\keybindings.ps1"
. "$modulesDir\aliases.ps1"
. "$modulesDir\navigation.ps1"
