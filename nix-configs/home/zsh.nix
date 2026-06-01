{
  config,
  lib,
  pkgs,
  ...
}: {
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
      path=("$HOME/.local/state/nix/profiles/home-manager/home-path/bin" "$HOME/.local/bin" "$GOPATH/bin" "$HOME/.cargo/bin" $path)
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 560 ''
        fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
      '')
      (lib.mkBefore ''
        function ensure_zcompiled {
          local src=$1
          if [[ -z "$src" || "$src" == /proc/self/fd/* || "$src" == /dev/fd/* || ! -f "$src" ]]; then
            return
          fi
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
}
