{config, ...}: let
  goPath = "${config.home.homeDirectory}/go";
in {
  programs.go = {
    enable = true;
    env = {
      GOPATH = goPath;
      GO111MODULE = "on";
    };
  };

  home = {
    sessionVariables = {
      GOPATH = goPath;
      GO111MODULE = "on";
    };
    sessionPath = ["${goPath}/bin"];
  };
}
