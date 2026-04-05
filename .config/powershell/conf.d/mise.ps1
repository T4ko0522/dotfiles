# mise 初期化（shimsパス追加 + activate のみ）
if (Get-Command mise -ErrorAction SilentlyContinue) {
    $miseShims = Join-Path $env:LOCALAPPDATA "mise\shims"
    if ($miseShims -and (Test-Path $miseShims) -and ($env:PATH -notlike "*$miseShims*")) {
        $env:PATH = "$miseShims;$env:PATH"
    }
    Invoke-Expression ((& mise activate pwsh) | Out-String)
}
