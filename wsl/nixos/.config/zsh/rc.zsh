ZSHRC_DIR="${0:a:h}"

# zsh オプション + PATH 浄化 (プラグイン読み込み前に行う)
source "$ZSHRC_DIR/rc/option.zsh"

# プラグイン設定 (sheldon が読み込むプラグインより先に設定値を export)
for f in "$ZSHRC_DIR/rc/pluginconfig/"*.zsh(N); do
  source "$f"
done

# sheldon でプラグイン読み込み (zsh-defer, autosuggestions, completions, fast-syntax-highlighting, zeno)
if command -v sheldon &>/dev/null; then
  eval "$(sheldon source)"
fi

# zsh-completions の fpath 反映後に compinit
autoload -Uz compinit && compinit -u

# エイリアス・キーバインド・関数
source "$ZSHRC_DIR/rc/alias.zsh"
source "$ZSHRC_DIR/rc/bindkey.zsh"
for f in "$ZSHRC_DIR/rc/functions/"*.zsh(N); do
  source "$f"
done
