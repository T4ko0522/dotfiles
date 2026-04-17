# Starship
eval "$(starship init zsh)"

# mise
# /mnt/c 配下の mise config を無視（Windows用 conf.d の誤読み込み・二重読み込み防止）
export MISE_IGNORED_CONFIG_PATHS="/mnt/c"
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# fzf マゼンタテーマ
export FZF_DEFAULT_OPTS="
  --color=fg:#c0caf5,bg:-1,hl:#c778dd
  --color=fg+:#c0caf5,bg+:#2a2040,hl+:#d19afc
  --color=info:#b48ead,prompt:#c778dd,pointer:#d19afc
  --color=marker:#c778dd,spinner:#b48ead,header:#7c3aed
  --border=rounded --margin=0,1
"
