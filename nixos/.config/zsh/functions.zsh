# Navigation
..() { cd ..; }
...() { cd ../..; }
....() { cd ../../..; }
.....() { cd ../../../..; }

cdp() { cd ~/Project; }
cdtako() { cd ~/Project/github.com/T4ko0522; }

# ghq + fzf でリポジトリ移動
ghcd() {
  local repo
  repo=$(ghq list -p | fzf --preview 'lsd -la {}')
  [ -n "$repo" ] && cd "$repo"
}

# yazi ラッパー（終了時に選択ディレクトリへ cd）
yz() {
  local tmp
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd "$cwd"
  fi
  rm -f -- "$tmp"
}

# WSL ↔ Windows ファイル同期
#   wsync push [local]          — 自動検出で WSL → Windows
#   wsync pull [local]          — 自動検出で Windows → WSL
#   wsync push [src] [dst]      — 明示的に src → dst
#   wsync pull [dst] [src]      — 明示的に src → dst
wsync() {
  local WIN_HOME="/mnt/c/Users/takow"
  local WSL_HOME="$HOME"
  local direction="$1"
  local path1="${2:-$(pwd)}"
  local path2="$3"

  path1="${path1%/}"
  [[ -n "$path2" ]] && path2="${path2%/}"

  local src dst
  if [[ -n "$path2" ]]; then
    # 明示的に2パス指定
    case "$direction" in
      push) src="$path1"; dst="$path2" ;;
      pull) src="$path2"; dst="$path1" ;;
    esac
  else
    # 自動検出
    local mirror
    if [[ "$path1" == "$WSL_HOME"* ]]; then
      mirror="${WIN_HOME}${path1#$WSL_HOME}"
    elif [[ "$path1" == "$WIN_HOME"* ]]; then
      mirror="${WSL_HOME}${path1#$WIN_HOME}"
    else
      echo "error: パスの自動検出ができません。2つのパスを明示してください"
      echo "usage: wsync push|pull [local] [remote]"
      return 1
    fi
    case "$direction" in
      push) src="$path1"; dst="$mirror" ;;
      pull) src="$mirror"; dst="$path1" ;;
    esac
  fi

  case "$direction" in
    push|pull)
      echo "$src/ → $dst/"
      rsync -av --delete --exclude='.git' "$src/" "$dst/"
      ;;
    *)
      echo "usage: wsync push|pull [local] [remote]"
      echo "  push  local → remote"
      echo "  pull  remote → local"
      echo "  パス省略時は自動検出（~/... ↔ /mnt/c/Users/takow/...）"
      ;;
  esac
}

# git init 時に .cursorrules を自動配置
git() {
  command git "$@"
  if [[ "$1" == "init" ]] && [[ $? -eq 0 ]]; then
    local rules="$HOME/.git_template/git-secrets/.cursorrules"
    if [[ -f "$rules" ]]; then
      cp "$rules" ./.cursorrules
      echo "Copied .cursorrules to $(pwd)"
    fi
  fi
}
