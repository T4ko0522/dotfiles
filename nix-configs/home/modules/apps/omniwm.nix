{
  config,
  dotfilesPath,
  localPackages,
  ...
}: let
  overview = localPackages.omniwmOverview;
  overviewApp = "${overview}/Applications/OmniWMOverview.app";
in {
  home.packages = [overview];

  launchd.agents.omniwm-overview = {
    enable = true;
    config = {
      ProgramArguments = ["/usr/bin/open" "-g" "-a" overviewApp];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  launchd.agents.omniwm-overview-gestures = {
    enable = true;
    config = {
      ProgramArguments = ["${overview}/bin/omniwm-overview-gestures" "--app-path" overviewApp];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/omniwm-overview-gestures.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/omniwm-overview-gestures.log";
    };
  };

  launchd.agents.omniwm = {
    enable = true;
    config = {
      Program = "/Applications/OmniWM.app/Contents/MacOS/OmniWM";
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  # OmniWM writes its complete configuration back to this file.
  xdg.configFile."omniwm/settings.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/omniwm/files/settings.toml";
  };
}
