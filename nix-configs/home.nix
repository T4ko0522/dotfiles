{
  config,
  lib,
  pkgs,
  dotfilesDir,
  ...
}:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  home.username = "t4ko";
  home.homeDirectory = "/home/t4ko";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.packages = with pkgs; [
    bat
    delta
    difftastic
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    gcc
    ghq
    git-lfs
    gnumake
    gomi
    jq
    just
    lazygit
    lsd
    neovim
    peco
    ripgrep
    starship
    tree-sitter
    unzip
    wezterm
    wl-clipboard
    xdg-utils
    yazi
    zoxide
  ];

  xdg.configFile = {
    "codex".source = link ".config/codex";
    "fastfetch".source = link ".config/fastfetch";
    "lazygit".source = link ".config/lazygit";
    "nvim".source = link ".config/nvim";
    "starship.toml".source = link ".config/starship.toml";
    "vim".source = link ".config/vim";
    "wezterm".source = link ".config/wezterm";
    "yazi".source = link ".config/yazi";
    "zsh/rc".source = link ".config/zsh/rc";
  };

  home.file = {
    ".gitconfig".source = link ".gitconfig";
    ".git_template/hooks".source = link ".git_template/hooks";
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "emacs";

    history = {
      path = "${config.xdg.configHome}/zsh/.zsh_history";
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      expireDuplicatesFirst = true;
    };

    sessionVariables = {
      MANPAGER = "nvim +Man!";
      LESSHISTFILE = "\${XDG_STATE_HOME:-$HOME/.local/state}/less/history";
      LISTMAX = "50";
    };

    envExtra = ''
      setopt no_global_rcs

      export ZRCDIR="$ZDOTDIR/rc"
      export LOCAL_ZSH_DIR="$HOME/.config/local/zsh"

      export EDITOR=nvim
      export VISUAL="$EDITOR"
      export GIT_EDITOR="$EDITOR"

      export GOPATH="$XDG_DATA_HOME/go"
      export GO111MODULE=on
      path=("$HOME/.local/bin" "$GOPATH/bin" "$HOME/.cargo/bin" $path)
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 560 ''
        fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
      '')
      (lib.mkBefore ''
        function ensure_zcompiled {
          local src=$1
          local zwc="$src.zwc"
          local dir="''${src:h}"
          if [[ ! -w "$dir" ]]; then
            return
          fi
          if [[ ! -r "$zwc" || "$src" -nt "$zwc" ]]; then
            zcompile "$src"
          fi
        }

        function source {
          ensure_zcompiled "$1"
          builtin source "$1"
        }
      '')
      ''
        fpath=("$ZRCDIR/functions" "$ZRCDIR/functions"/*(/N) $fpath)
        autoload -Uz "$ZRCDIR"/functions/*(-.N:t) "$ZRCDIR"/functions/**/*(-.N:t)

        source "$ZRCDIR/bindkey.zsh"
        source "$ZRCDIR/alias.zsh"
        source "$ZRCDIR/option.zsh"

        zstyle ':completion:*' matcher-list "" 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'
        zstyle ':completion:*' format '%B%F{blue}%d%f%b'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:default' menu select=2

        autoload -Uz run-help run-help-git run-help-openssl run-help-sudo
        autoload -Uz zmv
        umask 022

        if [[ -d "$LOCAL_ZSH_DIR" ]]; then
          for file in "$LOCAL_ZSH_DIR"/*.zsh(N); do
            source "$file"
          done
        fi

        source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      ''
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.stateVersion = "26.05";
}
