# git init 時に .cursorrules を自動配置 (PowerShell プロファイルと同様)
git() {
  command git "$@"
  local ret=$?
  if [[ "$1" == "init" && $ret -eq 0 ]]; then
    local rules="$HOME/.git_template/git-secrets/.cursorrules"
    if [[ -f "$rules" ]]; then
      cp "$rules" ./.cursorrules
      echo "Copied .cursorrules to $PWD"
    fi
  fi
  return $ret
}
