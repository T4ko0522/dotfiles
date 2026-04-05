# PSReadLine設定（入力補完・予測入力）
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -MaximumHistoryCount 16384
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -Colors @{
    Command              = "Green"
    Error                = "Red"
    InlinePrediction      = "Magenta"
    ListPrediction        = "Magenta"
    ListPredictionSelected = "#e066ff"
}

# Ctrl+F: ホーム以下のディレクトリをfzfで検索してcd
Set-PSReadLineKeyHandler -Key Ctrl+f -ScriptBlock {
    $dir = fd --type d --hidden --exclude .git --base-directory $env:USERPROFILE | fzf --reverse --border --height=40%
    if ($dir) {
        $fullPath = Join-Path $env:USERPROFILE $dir
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd '$fullPath'")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}
