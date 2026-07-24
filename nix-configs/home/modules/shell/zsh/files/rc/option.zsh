setopt correct

setopt extended_history
setopt share_history
setopt hist_verify
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_no_store
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_expand
setopt inc_append_history

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

unsetopt bg_nice
setopt list_packed
setopt no_beep
unsetopt list_types

if [[ -t 0 ]]; then
  stty -ixon
fi
