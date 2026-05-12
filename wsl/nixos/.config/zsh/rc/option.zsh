# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=16384
SAVEHIST=16384
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Completion (PowerShell の Tab → MenuComplete 相当)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' '+l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Misc
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt EXTENDED_GLOB

# Windows PATH 継承で混入する Windows 版 mise shims を除外
# (NixOS では mise を使わない方針のため、Windows shims が呼ばれて `mise: 見つかりません` になるのを防ぐ)
typeset -U path
path=("${(@)path:#/mnt/c/Users/*/AppData/Local/mise/*}")
