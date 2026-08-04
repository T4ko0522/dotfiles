#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ownership_file="$repo_root/docs/memo/dotfiles-ownership.tsv"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

if [[ "$(<"$repo_root/.chezmoiroot")" != "chezmoi" ]]; then
  printf '%s\n' '.chezmoiroot must point to chezmoi' >&2
  exit 1
fi

for mutable_dir in mutable/nvim mutable/cava mutable/shared/apm mutable/shared/lazygit mutable/shared/zed mutable/fcitx5; do
  if [[ ! -d "$repo_root/$mutable_dir" ]]; then
    printf 'mutable source does not exist: %s\n' "$mutable_dir" >&2
    exit 1
  fi
done

if [[ ! -f "$repo_root/mutable/shared/gitconfig" ]]; then
  printf '%s\n' 'mutable source does not exist: mutable/shared/gitconfig' >&2
  exit 1
fi

git_template_dir="$repo_root/chezmoi/private_dot_git_template/hooks"
for hook in commit-msg pre-commit prepare-commit-msg; do
  if [[ ! -f "$git_template_dir/executable_$hook" ]]; then
    printf 'git hook source does not exist: %s\n' "$git_template_dir/executable_$hook" >&2
    exit 1
  fi
done

templatedir="$(git config --file "$repo_root/mutable/shared/gitconfig" --get init.templatedir)"
if [[ "$templatedir" != '~/.git_template' ]]; then
  printf 'git template directory is inconsistent: %s\n' "$templatedir" >&2
  exit 1
fi

hooks_path="$(git config --file "$repo_root/mutable/shared/gitconfig" --get core.hookspath)"
if [[ "$hooks_path" != '~/.git_template/hooks' ]]; then
  printf 'git hooks path is inconsistent: %s\n' "$hooks_path" >&2
  exit 1
fi

if ! command -v git-secrets >/dev/null 2>&1; then
  printf '%s\n' 'git-secrets is required by the managed Git hooks' >&2
  exit 1
fi

declare -A targets=()
while IFS=$'\t' read -r profile target owner _mode _source; do
  [[ -z "$profile" || "$profile" == profile ]] && continue

  case "$profile" in
    windows | nixos | wsl) ;;
    *)
      printf 'invalid profile: %s\n' "$profile" >&2
      exit 1
      ;;
  esac

  case "$owner" in
    chezmoi | nix | unmanaged) ;;
    *)
      printf 'invalid owner: %s\n' "$owner" >&2
      exit 1
      ;;
  esac

  key="$profile:$target"
  if [[ -n "${targets[$key]:-}" ]]; then
    printf 'duplicate ownership: %s\n' "$key" >&2
    exit 1
  fi
  targets[$key]="$owner"
done < "$ownership_file"

for profile in windows nixos wsl; do
  rendered="$temp_dir/chezmoi-$profile.toml"
  chezmoi \
    --config /dev/null \
    --config-format toml \
    execute-template \
    --init \
    --promptChoice "Environment profile=$profile" \
    --file "$repo_root/chezmoi/.chezmoi.toml.tmpl" > "$rendered"

  if ! grep -q "profile = \"$profile\"" "$rendered"; then
    printf 'profile was not rendered: %s\n' "$profile" >&2
    exit 1
  fi

  if ! grep -q 'username = "t4ko"' "$rendered"; then
    printf 'username was not rendered for profile: %s\n' "$profile" >&2
    exit 1
  fi

  rendered_script="$temp_dir/create-windows-junctions-$profile.ps1"
  chezmoi \
    --config "$rendered" \
    execute-template \
    --file "$repo_root/chezmoi/run_after_create-windows-junctions.ps1.tmpl" > "$rendered_script"
  if [[ "$profile" == windows ]]; then
    if ! grep -q 'mutable\\nvim' "$rendered_script" \
      || ! grep -q 'mutable\\cava' "$rendered_script" \
      || ! grep -q 'CHEZMOI_WINDOWS_APPDATA' "$rendered_script" \
      || ! grep -q 'CHEZMOI_WINDOWS_DOCUMENTS' "$rendered_script" \
      || ! grep -q 'mutable\\shared\\zed' "$rendered_script"; then
      printf '%s\n' 'Windows link script is incomplete' >&2
      exit 1
    fi
  elif grep -q '[^[:space:]]' "$rendered_script"; then
    printf 'Windows junction script rendered for profile: %s\n' "$profile" >&2
    exit 1
  fi

  source_path="$(chezmoi --source "$repo_root" --config "$rendered" source-path)"
  if [[ "$source_path" != "$repo_root/chezmoi" ]]; then
    printf 'unexpected source root: %s\n' "$source_path" >&2
    exit 1
  fi

  mkdir -p "$temp_dir/home-$profile"
  managed_file="$temp_dir/managed-$profile"
  chezmoi \
    --source "$repo_root" \
    --config "$rendered" \
    --destination "$temp_dir/home-$profile" \
    managed \
    --include files,symlinks \
    --path-style relative > "$managed_file"

  while IFS=$'\t' read -r row_profile target owner mode _source; do
    [[ "$row_profile" == "$profile" ]] || continue
    [[ "$mode" == junction || "$mode" == native-link ]] && continue

    is_managed=false
    while IFS= read -r managed_target; do
      if [[ "$managed_target" == "$target" || "$managed_target" == "$target/"* ]]; then
        is_managed=true
        break
      fi
    done < "$managed_file"

    if [[ "$owner" == chezmoi && "$is_managed" != true ]]; then
      printf 'chezmoi target is missing for %s: %s\n' "$profile" "$target" >&2
      exit 1
    fi
    if [[ "$owner" != chezmoi && "$is_managed" == true ]]; then
      printf 'non-chezmoi target is managed for %s: %s\n' "$profile" "$target" >&2
      exit 1
    fi
  done < "$ownership_file"

  chezmoi \
    --source "$repo_root" \
    --config "$rendered" \
    --destination "$temp_dir/home-$profile" \
    --no-tty \
    --dry-run \
    apply

  chezmoi \
    --source "$repo_root" \
    --config "$rendered" \
    --destination "$temp_dir/home-$profile" \
    --exclude scripts \
    --no-tty \
    apply

  git_init_dir="$temp_dir/git-init-$profile"
  git_init_output="$(
    HOME="$temp_dir/home-$profile" \
    XDG_CONFIG_HOME="$temp_dir/home-$profile/.config" \
    GIT_CONFIG_GLOBAL="$temp_dir/home-$profile/.gitconfig" \
    GIT_CONFIG_NOSYSTEM=1 \
    git init "$git_init_dir" 2>&1
  )"
  if grep -Fq 'templates not found' <<<"$git_init_output"; then
    printf 'git init emitted a template warning for profile: %s\n%s\n' "$profile" "$git_init_output" >&2
    exit 1
  fi
  for hook in commit-msg pre-commit prepare-commit-msg; do
    if [[ ! -f "$git_init_dir/.git/hooks/$hook" ]]; then
      printf 'git init did not copy hook for %s: %s\n' "$profile" "$hook" >&2
      exit 1
    fi
  done
  active_hooks_path="$(
    HOME="$temp_dir/home-$profile" \
    XDG_CONFIG_HOME="$temp_dir/home-$profile/.config" \
    GIT_CONFIG_GLOBAL="$temp_dir/home-$profile/.gitconfig" \
    GIT_CONFIG_NOSYSTEM=1 \
    git -C "$git_init_dir" rev-parse --git-path hooks
  )"
  for hook in commit-msg pre-commit prepare-commit-msg; do
    if [[ ! -f "$active_hooks_path/$hook" ]]; then
      printf 'active git hook is missing for %s: %s\n' "$profile" "$hook" >&2
      exit 1
    fi
  done

  if [[ "$profile" == windows ]]; then
    codex_config="$temp_dir/home-$profile/.codex/config.toml"
    printf '\n# preserve-existing-config\n' >> "$codex_config"
    chezmoi \
      --source "$repo_root" \
      --config "$rendered" \
      --destination "$temp_dir/home-$profile" \
      --exclude scripts \
      --force \
      --no-tty \
      apply
    if ! grep -q '# preserve-existing-config' "$codex_config"; then
      printf '%s\n' 'chezmoi overwrote the existing Windows Codex config' >&2
      exit 1
    fi
  fi

  claude_settings="$temp_dir/home-$profile/.claude/settings.json"
  if [[ ! -f "$claude_settings" ]]; then
    printf 'Claude settings were not rendered for profile: %s\n' "$profile" >&2
    exit 1
  fi
  case "$profile" in
    windows)
      if ! grep -q '%USERPROFILE%.*ccwin-hook.ps1' "$claude_settings"; then
        printf '%s\n' 'Windows Claude hooks were not rendered' >&2
        exit 1
      fi
      if grep -Eq 'C:\\Users\\(HP|takow)' "$temp_dir/home-$profile/.config/yasb/config.yaml"; then
        printf '%s\n' 'YASB contains a hard-coded user profile' >&2
        exit 1
      fi
      ;;
    nixos)
      if ! grep -q 'claude-notify-hook.sh' "$claude_settings"; then
        printf '%s\n' 'NixOS Claude hooks were not rendered' >&2
        exit 1
      fi
      ;;
    wsl)
      if grep -q '"hooks"' "$claude_settings"; then
        printf '%s\n' 'WSL Claude settings unexpectedly contain hooks' >&2
        exit 1
      fi
      ;;
  esac
done
