{
  config,
  osConfig,
  pkgs,
  ...
}: let
  signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519_signing_${osConfig.networking.hostName}.pub";
in {
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = [
      {
        include.path = "~/.gitconfig.local";
      }
      {
        alias = {
          ci = "commit";
          st = "status";
          br = "branch";
          co = "checkout";
          hist = ''log --pretty=format:"%Cgreen%h %Creset%cd %Cblue[%cn] %Creset%s%C(yellow)%d%C(reset)" --graph --date=relative --decorate --all'';
          llog = ''log --graph --name-status --pretty=format:"%C(red)%h %C(reset)(%cd) %C(green)%an %Creset%s %C(yellow)%d%Creset" --date=relative'';
          df = ''!git hist | fzf | awk '{print $2}' | xargs -I {} git diff {}^ {}'';
          ps = ''!git push origin $(git rev-parse --abbrev-ref HEAD)'';
          pl = ''!git pull origin $(git rev-parse --abbrev-ref HEAD)'';
        };
        push.autoSetupRemote = true;
        commit.gpgSign = true;
        tag.gpgSign = true;
        gpg = {
          format = "ssh";
          ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
        };
        secrets = {
          providers = "git secrets --aws-provider";
          patterns = [
            ''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}''
            ''("|')?(AWS|aws|Aws)?_?(SECRET|secret|Secret)?_?(ACCESS|access|Access)?_?(KEY|key|Key)("|')?\s*(:|=>|=)\s*("|')?[A-Za-z0-9/\+=]{40}("|')?''
            ''("|')?(AWS|aws|Aws)?_?(ACCOUNT|account|Account)_?(ID|id|Id)?("|')?\s*(:|=>|=)\s*("|')?[0-9]{4}-?[0-9]{4}-?[0-9]{4}("|')?''
          ];
          allowed = [
            "AKIAIOSFODNN7EXAMPLE"
            "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
          ];
        };
        core.hooksPath = "~/.git_template/hooks";
        init = {
          defaultBranch = "main";
          templatedir = "~/.git_template";
        };
        http.postBuffer = 524288000;
        ghq.root = "~/Project";
        user = {
          email = "tako.renraku1@gmail.com";
          name = "T4ko0522";
          signingKey = signingKey;
        };
        safe.directory = "%(prefix)///wsl.localhost/NixOS/home/t4ko/dotfiles";
        credential = {
          "https://github.com".helper = [
            ""
            "!gh auth git-credential"
          ];
          "https://gist.github.com".helper = [
            ""
            "!gh auth git-credential"
          ];
        };
      }
    ];
  };

  home.file = {
    ".git_template/hooks/commit-msg" = {
      source = ./files/git-template/hooks/executable_commit-msg;
      executable = true;
    };
    ".git_template/hooks/pre-commit" = {
      source = ./files/git-template/hooks/executable_pre-commit;
      executable = true;
    };
    ".git_template/hooks/prepare-commit-msg" = {
      source = ./files/git-template/hooks/executable_prepare-commit-msg;
      executable = true;
    };
  };
}
