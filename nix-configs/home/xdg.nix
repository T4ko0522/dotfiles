{
  config,
  lib,
  pkgs,
  llm-agents,
  ...
}: let
  # link (out-of-store): mkOutOfStoreSymlink で store の外にある「書き込み可能な実体」を指す。
  # dotfilesDir (= self.outPath) は store 内 (読み取り専用) なので、ライブの作業ツリー
  # (~/dotfiles) を基準に symlink を張る。プログラム自身が設定 dir/file へ書き戻すもの
  # (lazygit の state.yml、nvim の lazy-lock.json、zsh の .zwc、codex/claude のランタイム状態、
  # GUI 由来で再書き込みされる fcitx5 など) に使う。編集に rebuild は不要。
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";

  # store (in-store): path をそのまま nix store へコピーし、読み取り専用で配置する。
  # プログラムが書き込まない静的設定に使う。変更には rebuild (just os-switch) が必要になる
  # 代わりに再現性が上がり、誤編集で壊れない。flake 評価で参照するため対象は Git track 必須。
  store = path: ../../. + "/${path}";

  claudeSettings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile (store ".config/shared/claude/settings.json"))) (
    builtins.fromJSON (builtins.readFile (store ".config/nixos/claude/settings.hooks.json"))
  );
in {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/xhtml+xml" = "brave-browser.desktop";
        "audio/aac" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/mpeg" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/opus" = "mpv.desktop";
        "audio/wav" = "mpv.desktop";
        "audio/x-m4a" = "mpv.desktop";
        "image/avif" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "video/mp4" = "mpv.desktop";
        "video/mpeg" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        "x-scheme-handler/discord" = "vesktop.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };
    };

    configFile = {
      "mimeapps.list".force = true;
      # in-store: プログラムが書き込まない静的設定。
      "fastfetch".source = store ".config/shared/fastfetch";
      "claudex/config.toml".source = link ".config/shared/claudex/config.toml"; # profile の追加・更新を claudex から行う
      "starship.toml".source = store ".config/shared/starship.toml";
      "vim".source = store ".config/shared/vim";
      "wezterm".source = store ".config/shared/wezterm";
      "yazi".source = store ".config/shared/yazi";
      # out-of-store: プログラム自身が dir/file へ書き戻すもの。
      "lazygit".source = link ".config/shared/lazygit"; # state.yml を書き込む
      "nvim".source = link ".config/shared/nvim"; # lazy-lock.json を書き込む
      "zed".source = link ".config/shared/zed"; # GUI 設定変更で settings.json を書き戻す
      "zsh/rc".source = link ".config/nixos/zsh/rc"; # .zwc を zcompile する
      "fcitx5/config".source = link ".config/nixos/fcitx5/config"; # GUI 設定で再書き込み
    };

    dataFile."applications/mimeapps.list".force = true;
  };

  home.file = {
    # in-store: プログラムが書き込まない静的設定。
    ".git_template/hooks".source = store ".git_template/hooks";
    ".codex/AGENTS.md".source = store ".config/shared/codex/AGENTS.md";
    ".codex/agents".source = store ".config/shared/codex/agents";
    ".codex/rules".source = store ".config/shared/codex/rules";
    ".claude/CLAUDE.md".source = store ".config/shared/claude/CLAUDE.md";
    ".claude/agents".source = store ".config/shared/claude/agents";
    ".claude/statusline.sh".source = store ".config/shared/claude/statusline.sh";
    ".claude/claude-icon.svg".source = store ".config/shared/claude/claude-icon.svg";
    ".claude/claude-notify-hook.sh" = {
      source = store ".config/nixos/claude/claude-notify-hook.sh";
      executable = true;
    };

    # out-of-store: プログラム自身が書き戻すもの。
    ".gitconfig".source = link ".gitconfig"; # git config --global で書き込む
    # .codex/config.toml は home.activation.seedCodexConfig で管理する (下記)。
    # out-of-store symlink にすると codex が marketplaces/plugins/mcp_servers 等の実行時状態を
    # dotfiles の git 追跡ファイルへ書き戻し汚染するため、静的テンプレートから初回シードした
    # 「実ファイル」を codex に所有させ、git ツリーから切り離す。
    ".claude/skills".source = link ".config/shared/apm/.claude/skills"; # apm install の生成物 (source は .config/shared/apm/packages/<category>/.apm/skills/)
  };

  # Claude settings.json: 共通 base に NixOS 固有 hooks をマージして生成する。
  # Windows 側の setup_windows.ps1 と同じく、通知 hook の依存は OS 固有ディレクトリに閉じ込める。
  home.activation.generateClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    claude_dir="${config.home.homeDirectory}/.claude"
    mkdir -p "$claude_dir"
    rm -f "$claude_dir/settings.json"
    cat > "$claude_dir/settings.json" <<'EOF'
    ${builtins.toJSON claudeSettings}
    EOF
    chmod 0644 "$claude_dir/settings.json"
  '';

  # Codex config.toml: 静的テンプレートから ~/.codex/config.toml を「実ファイル」として初回シードする。
  # codex は起動時に marketplaces/plugins/mcp_servers 等をこのファイルへ書き戻すため、out-of-store
  # symlink にすると dotfiles の git 追跡ファイルが汚染される。実ファイル化して codex に所有させ、
  # dotfiles 側は静的な初期値テンプレートとしてのみ保持する (再生成可能に保つ)。
  # 既存が symlink (旧構成の名残) または未作成の場合のみテンプレートで初期化し、実ファイルは温存する。
  home.activation.seedCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    codex_cfg="${config.home.homeDirectory}/.codex/config.toml"
    codex_tmpl="${config.home.homeDirectory}/dotfiles/.config/shared/codex/config.toml"
    mkdir -p "${config.home.homeDirectory}/.codex"
    if [ -L "$codex_cfg" ] || [ ! -e "$codex_cfg" ]; then
      rm -f "$codex_cfg"
      cp "$codex_tmpl" "$codex_cfg"
      chmod u+w "$codex_cfg"
    fi
  '';

  # Codex の設定と Desktop の thread state は実行時に書き換えられるため、
  # 過去の root-wide write を安全な値へ一度だけ移行する。
  home.activation.migrateCodexSandboxState = lib.hm.dag.entryAfter ["seedCodexConfig"] ''
    codex_dir="${config.home.homeDirectory}/.codex"
    codex_cfg="$codex_dir/config.toml"

    # 旧 personal profile の `:root = "write"` は workspace root として `/` を
    # Desktop に渡し得る。現在のテンプレートと同じ read-only root に揃える。
    if [ -f "$codex_cfg" ] \
      && ${pkgs.gnugrep}/bin/grep -q '^default_permissions = "personal"$' "$codex_cfg" \
      && ${pkgs.gnugrep}/bin/grep -q '^":root" = "write"$' "$codex_cfg"; then
      ${pkgs.gnused}/bin/sed -i 's/^":root" = "write"$/":root" = "read"/' "$codex_cfg"
    fi

    # Retained roots are merged into later Desktop requests. Remove only `/` from
    # this specific state key; project roots and all other Codex state are preserved.
    for state_file in "$codex_dir/.codex-global-state.json" "$codex_dir/.codex-global-state.json.bak"; do
      [ -f "$state_file" ] || continue
      if ${pkgs.jq}/bin/jq -e '
        any(
          ((.["thread-writable-roots"] // {}) | to_entries[]?.value?);
          type == "array" and any(.[]; . == "/")
        )
      ' "$state_file" >/dev/null; then
        state_tmp="$state_file.tmp.$$"
        if ${pkgs.jq}/bin/jq '
          if type == "object" and (.["thread-writable-roots"] | type) == "object" then
            .["thread-writable-roots"] |= with_entries(
              .value |= if type == "array" then map(select(. != "/")) else . end
            )
          else
            .
          end
        ' "$state_file" > "$state_tmp"; then
          ${pkgs.coreutils}/bin/chmod --reference="$state_file" "$state_tmp"
          ${pkgs.coreutils}/bin/mv "$state_tmp" "$state_file"
        else
          ${pkgs.coreutils}/bin/rm -f "$state_tmp"
        fi
      fi
    done
  '';

  # apm install: .config/shared/apm/packages/<category>/.apm/skills/ (source) から各targetのskills dirへdeployする。
  # APMはCodex向けskillを`.agents/skills`に生成する。Codexは~/.codex/skills/.systemを保持する必要があるため、skillごとのリンクを後段で作る。
  home.activation.apmInstallSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cd "${config.home.homeDirectory}/dotfiles/.config/shared/apm"
    # activation は systemd 環境で走るため ~/.zshenv は読まれない。gh CLI の keyring からトークンを渡し、
    # apm install が mizchi/skills などを clone する際に GitHub 認証が通るようにする。
    export GITHUB_TOKEN="$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)"
    ${llm-agents.packages.${pkgs.system}.apm}/bin/apm install
  '';

  home.activation.linkCodexSkills = lib.hm.dag.entryAfter ["apmInstallSkills"] ''
    source_dir="${config.home.homeDirectory}/dotfiles/.config/shared/apm/.agents/skills"
    target_dir="${config.home.homeDirectory}/.codex/skills"
    mkdir -p "$target_dir"
    find "$target_dir" -maxdepth 1 -type l -lname "$source_dir/*" -delete
    for skill in "$source_dir"/*; do
      [ -d "$skill" ] || continue
      ln -sfn "$skill" "$target_dir/$(basename "$skill")"
    done
  '';

  # opencode 向け skill: apm 生成物 (.agents/skills) を ~/.config/opencode/skills/ へ張る。
  home.activation.linkOpencodeSkills = lib.hm.dag.entryAfter ["apmInstallSkills"] ''
    source_dir="${config.home.homeDirectory}/dotfiles/.config/shared/apm/.agents/skills"
    target_dir="${config.home.homeDirectory}/.config/opencode/skills"
    mkdir -p "$target_dir"
    find "$target_dir" -maxdepth 1 -type l -lname "$source_dir/*" -delete
    for skill in "$source_dir"/*; do
      [ -d "$skill" ] || continue
      ln -sfn "$skill" "$target_dir/$(basename "$skill")"
    done
  '';
}
