{
  config,
  dotfilesPath,
  ...
}: {
  home.file = {
    ".gitconfig".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/development/files/gitconfig";
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
