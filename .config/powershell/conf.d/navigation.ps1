# 上位ディレクトリへ一気に移動
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# %USERNAME%/Projectに移動
function cdp {
    Set-Location "$env:USERPROFILE\Project"
}

# %USERNAME%/Project/github.com/T4ko0522に移動
function cdtako {
    Set-Location "$env:USERPROFILE\Project\github.com\T4ko0522"
}

# ghqとfzfを使用してリポジトリに移動
function ghcd() {
    Set-Location "$(ghq root)/$(ghq list | fzf --reverse --border --height=40%)"
}

# yaziで移動したディレクトリにシェルもcdするラッパー
function yz {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -ErrorAction SilentlyContinue
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location -Path $cwd
    }
    Remove-Item -Path $tmp -ErrorAction SilentlyContinue
}
