# git init 後に .cursorrules を自動配置
function git {
    if ($args.Count -ge 1 -and $args[0] -eq "init") {
        git.exe @args
        $src = Join-Path $env:USERPROFILE ".git_template/git-secrets/.cursorrules"
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination ".cursorrules" -Force
        }
    } else {
        git.exe @args
    }
}
