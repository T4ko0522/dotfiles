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
# パスを自動変換して rsync で同期する
#   wsync push [path]  — WSL → Windows
#   wsync pull [path]  — Windows → WSL
wsync() {
  local WIN_HOME="/mnt/c/Users/takow"
  local WSL_HOME="$HOME"
  local direction="$1"
  local target="${2:-$(pwd)}"

  # 末尾スラッシュを正規化
  target="${target%/}"

  # ミラーパスを自動検出
  local mirror
  if [[ "$target" == "$WSL_HOME"* ]]; then
    mirror="${WIN_HOME}${target#$WSL_HOME}"
  elif [[ "$target" == "$WIN_HOME"* ]]; then
    mirror="${WSL_HOME}${target#$WIN_HOME}"
  else
    echo "error: パスが $WSL_HOME または $WIN_HOME 配下ではありません"
    echo "usage: wsync push|pull [path]"
    return 1
  fi

  case "$direction" in
    push)
      echo "$target/ → $mirror/"
      rsync -av --delete --exclude='.git' "$target/" "$mirror/"
      ;;
    pull)
      echo "$mirror/ → $target/"
      rsync -av --delete --exclude='.git' "$mirror/" "$target/"
      ;;
    *)
      echo "usage: wsync push|pull [path]"
      echo "  push  WSL → Windows"
      echo "  pull  Windows → WSL"
      echo "  path  省略時はカレントディレクトリ"
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
