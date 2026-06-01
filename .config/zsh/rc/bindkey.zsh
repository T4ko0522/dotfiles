# Use emacs keybinds.
bindkey -e
bindkey -r '^X^F'

zle -N ghq-fzf
bindkey '^g' ghq-fzf

zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^p' history-beginning-search-backward-end
bindkey '^n' history-beginning-search-forward-end

autoload -Uz smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
bindkey '^[.' insert-last-word

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^[e' edit-command-line

bindkey '^X^R' redo
bindkey '^Xr' redo
