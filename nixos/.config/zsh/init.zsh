# Starship
eval "$(starship init zsh)"

# mise
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Environment
export CLAUDE_CODE_EFFORT_LEVEL="max"

# fzf マゼンタテーマ
export FZF_DEFAULT_OPTS="
  --color=fg:#c0caf5,bg:-1,hl:#c778dd
  --color=fg+:#c0caf5,bg+:#2a2040,hl+:#d19afc
  --color=info:#b48ead,prompt:#c778dd,pointer:#d19afc
  --color=marker:#c778dd,spinner:#b48ead,header:#7c3aed
  --border=rounded --margin=0,1
"
