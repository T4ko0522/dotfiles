# Windows 側のディレクトリを参照 (PowerShell プロファイルと同じ場所)
cdp()    { cd /mnt/c/Users/takow/Project; }
cdtako() { cd /mnt/c/Users/takow/Project/github.com/T4ko0522; }

# ghq + fzf でリポジトリ移動
ghcd() {
  local repo
  repo=$(ghq list -p | fzf --reverse --border --height=40% --preview 'lsd -la {}')
  [[ -n "$repo" ]] && cd "$repo"
}

# yazi ラッパー (終了時に選択ディレクトリへ cd)
yz() {
  local tmp
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    cd "$cwd"
  fi
  rm -f -- "$tmp"
}
