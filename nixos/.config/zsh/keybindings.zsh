# Ctrl+F: fzf でディレクトリ検索して cd
fzf-cd-widget() {
  local dir
  dir=$(fd --type d . "$HOME" | fzf)
  if [ -n "$dir" ]; then
    BUFFER="cd $dir"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-cd-widget
bindkey '^F' fzf-cd-widget
