$hour = (Get-Date).Hour

if ($hour -ge 5 -and $hour -lt 11) {
  Write-Output "Good morning"
} elseif ($hour -ge 11 -and $hour -lt 17) {
  Write-Output "Good afternoon"
} elseif ($hour -ge 17 -and $hour -lt 23) {
  Write-Output "Good evening"
} else {
  Write-Output "Good night"
}
