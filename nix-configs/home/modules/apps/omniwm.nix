{
  config,
  dotfilesPath,
  ...
}: {
  t4ko.macMode.targets.omniwm = {
    agent = "omniwm";
    appPath = "/Applications/OmniWM.app";
  };

  launchd.agents.omniwm = {
    enable = true;
    config = {
      Program = "/Applications/OmniWM.app/Contents/MacOS/OmniWM";
      RunAtLoad = false;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  # OmniWM writes its complete configuration back to this file.
  xdg.configFile."omniwm/settings.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix-configs/home/modules/apps/omniwm/files/settings.toml";
  };
}
