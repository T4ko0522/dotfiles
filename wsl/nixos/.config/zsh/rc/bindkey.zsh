bindkey -e

# Ctrl+F: fd + fzf でホーム以下のディレクトリを検索して cd (PowerShell の Ctrl+F 相当)
fzf-cd-widget() {
  emulate -L zsh
  local dir
  dir=$(fd --type d --hidden --exclude .git . "$HOME" \
        | fzf --reverse --border --height=40%)
  if [[ -n "$dir" ]]; then
    BUFFER="cd ${(q)dir}"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-cd-widget
bindkey '^F' fzf-cd-widget
