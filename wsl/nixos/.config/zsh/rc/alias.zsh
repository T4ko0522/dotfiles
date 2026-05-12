# コマンド置換
alias vi="nvim"
# PowerShell プロファイル側 ls 関数 (常に long 表示) に揃える
# LANG=en_US.UTF-8 を付けて日付表記を InvariantCulture (Sat 09 May 17:43) に統一
alias ls="LANG=en_US.UTF-8 lsd -l"
alias la="LANG=en_US.UTF-8 lsd -la"
alias ll="LANG=en_US.UTF-8 lsd -la"
alias cat="bat"
alias grep="rg"
alias find="fd"

# WSL: Explorer 連携 (wslu 同梱の wslview)
alias open="wslview"

# 上位ディレクトリ移動 (PowerShell 側の ...,...., ..... 相当)
alias -- ..="cd .."
alias -- ...="cd ../.."
alias -- ....="cd ../../.."
alias -- .....="cd ../../../.."
