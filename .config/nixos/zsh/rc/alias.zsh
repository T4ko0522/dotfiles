# common
alias v='nvim'
alias cls='clear'
alias ...='../../'
alias ....='../../../'
alias .....='../../../../'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
else
  alias ls='ls -F --color=auto'
fi

if command -v gomi >/dev/null 2>&1; then
  alias gm='gomi'
fi

alias lg='lazygit'
alias ff='fastfetch'
alias y='yy'

hash -d xdata="$XDG_DATA_HOME"
hash -d nvim="$XDG_DATA_HOME/nvim"
hash -d dotfiles="$HOME/dotfiles"
