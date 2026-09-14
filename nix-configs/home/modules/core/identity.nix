{
  editor ? "zeditor --wait",
  homeDirectory,
  username,
  ...
}: {
  home = {
    inherit homeDirectory username;
    stateVersion = "26.05";

    sessionVariables = {
      EDITOR = editor;
      VISUAL = editor;
    };
  };
}
