# common
alias history='fc -l -10'
alias v='nvim'
alias yz='yazi'
alias cls='clear'
alias ct='/home/t4ko/Project/github.com/T4ko0522'
alias cdp='/home/t4koProject'
alias la='lsd -lah'
alias ..='../'
alias ...='../../'
alias ....='../../../'
alias .....='../../../../'

if command -v eza >/dev/null 2>&1; then
  export EZA_COLORS='hd=1;38;2;180;190;254:di=1;38;2;245;194;231:ex=1;38;2;148;226;213:fi=1;38;2;245;224;220:ln=38;2;137;180;250:or=38;2;243;139;168:ur=38;2;180;190;254:uw=38;2;137;180;250:ux=38;2;116;199;236:ue=38;2;116;199;236:gr=38;2;137;220;235:gw=38;2;148;226;213:gx=38;2;166;227;161:tr=38;2;249;226;175:tw=38;2;250;179;135:tx=38;2;235;160;172:sn=1;38;2;166;227;161:sb=1;38;2;166;227;161:uu=38;2;203;166;247:un=38;2;203;166;247:uR=38;2;203;166;247:gu=38;2;203;166;247:gn=38;2;203;166;247:gR=38;2;203;166;247:da=38;2;137;220;235:ic=1'
  alias ls='eza -l --header --icons=auto --group-directories-first'
else
  alias ls='ls -lF --color=auto'
fi

if command -v gomi >/dev/null 2>&1; then
  alias gm='gomi'
fi

alias lg='lazygit'
alias ff='fastfetch'
alias y='yy'
# 旧 `cx` エイリアスが読み込まれたままの既存シェルでも、関数版へ移行する。
unalias cx 2>/dev/null
alias cxa='cx-account'


function open {
  local target="${1:-.}"

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$target" >/dev/null 2>&1 &!
  elif command -v nautilus >/dev/null 2>&1; then
    nautilus "$target" >/dev/null 2>&1 &!
  else
    print -u2 'open: xdg-open or nautilus is required'
    return 127
  fi
}

function ghcd {
  if ! command -v ghq >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
    print -u2 'ghcd: ghq and fzf are required'
    return 127
  fi

  local src
  src=$(ghq list | fzf --preview 'bat --color=always --style=header,grid --line-range :80 "$(ghq root)"/{}/README.* 2>/dev/null') || return
  [[ -n "$src" ]] && cd "$(ghq root)/$src"
}

hash -d xdata="$XDG_DATA_HOME"
hash -d nvim="$XDG_DATA_HOME/nvim"
hash -d dotfiles="$HOME/dotfiles"
