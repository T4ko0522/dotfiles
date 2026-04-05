# モジュールのインポート
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# https://github.com/antfu-collective/ni とNew-Itemの競合を無効化
Remove-Item Alias:ni -Force -ErrorAction Ignore

# yasb 自動起動
if (-not (Get-Process -Name yasb -ErrorAction SilentlyContinue)) {
    Start-Process yasb -WindowStyle Hidden
}

# Starship プロンプト初期化
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
