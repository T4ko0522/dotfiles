{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep escapeShellArg mapAttrs';

  positiveInt = lib.types.ints.positive;
  percentage = lib.types.addCheck lib.types.number (value: value > 0 && value <= 100);

  appType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.strMatching ".+";
        description = "Name used when reporting progress and errors.";
      };

      command = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.str;
        description = "Command and arguments used when no matching window exists.";
      };

      startupTimeout = lib.mkOption {
        type = positiveInt;
        default = 60;
        description = "Maximum seconds to wait for a tiled application window after launch.";
      };

      matcher = {
        appId = lib.mkOption {
          type = lib.types.strMatching ".+";
          description = "Regular expression matched against the Niri app_id.";
        };

        title = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional regular expression matched against the window title.";
        };
      };

      output = lib.mkOption {
        type = lib.types.strMatching ".+";
        description = "Niri output on which to place the window.";
      };

      workspace = lib.mkOption {
        type = positiveInt;
        description = "One-based workspace index on the target output.";
      };

      column = lib.mkOption {
        type = positiveInt;
        description = "One-based column index within the target workspace.";
      };

      columnWidth = lib.mkOption {
        type = percentage;
        description = "Column width as a percentage of the output width.";
      };
    };
  };

  presetType = lib.types.submodule {
    options.apps = lib.mkOption {
      type = lib.types.nonEmptyListOf appType;
      description = "Applications to launch and arrange, in launch order.";
    };
  };

  commandPaths = {
    niri = lib.getExe pkgs.niri;
    jq = lib.getExe pkgs.jq;
    date = "${pkgs.coreutils}/bin/date";
    realpath = "${pkgs.coreutils}/bin/realpath";
    head = "${pkgs.coreutils}/bin/head";
    sleep = "${pkgs.coreutils}/bin/sleep";
    systemd_run = "${pkgs.systemd}/bin/systemd-run";
    systemctl = "${pkgs.systemd}/bin/systemctl";
    flock = lib.getExe' pkgs.util-linux "flock";
  };

  renderTemplate = path: values: let
    replacements = commandPaths // values;
  in
    lib.replaceStrings
    (map (name: "@${name}@") (builtins.attrNames replacements))
    (builtins.attrValues replacements)
    (builtins.readFile path);

  renderCommand = command: concatMapStringsSep " " escapeShellArg command;

  renderApp = presetName: app: let
    presetHash = builtins.substring 0 16 (builtins.hashString "sha256" presetName);
    appHash = builtins.substring 0 16 (builtins.hashString "sha256" (builtins.toJSON {
      inherit (app) name command matcher;
    }));
    unitPrefix = "t4ko-app-preset-${presetHash}-${appHash}";
    titlePattern =
      if app.matcher.title == null
      then ""
      else app.matcher.title;
    hasTitlePattern =
      if app.matcher.title == null
      then "false"
      else "true";
  in
    renderTemplate ./app-presets/files/app.sh {
      app_name = escapeShellArg app.name;
      app_id_pattern = escapeShellArg app.matcher.appId;
      title_pattern = escapeShellArg titlePattern;
      has_title_pattern = hasTitlePattern;
      app_output = escapeShellArg app.output;
      unit_prefix = unitPrefix;
      command = escapeShellArg (builtins.head app.command);
      arguments = renderCommand (builtins.tail app.command);
      startup_attempts = toString (app.startupTimeout * 10);
      startup_timeout = toString app.startupTimeout;
      workspace = toString app.workspace;
      column = toString app.column;
      column_width = toString app.columnWidth;
    };

  mkPresetScript = presetName: preset: let
    presetHash = builtins.hashString "sha256" presetName;
  in {
    executable = true;
    text = lib.concatStringsSep "\n" [
      "#!${pkgs.runtimeShell}"
      "# @vicinae.schemaVersion 1"
      "# @vicinae.title Apps: ${presetName}"
      "# @vicinae.mode compact"
      "# @vicinae.icon 🪟"
      ''# @vicinae.keywords ["apps", "preset", "workspace", "startup"]''
      ""
      (lib.trim (renderTemplate ./app-presets/files/main.sh {
        preset_name = escapeShellArg presetName;
        preset_hash = presetHash;
        apps = concatMapStringsSep "\n" (renderApp presetName) preset.apps;
      }))
      ""
    ];
  };

  presetScripts =
    mapAttrs' (
      presetName: preset:
        lib.nameValuePair "vicinae/scripts/apps-${builtins.hashString "sha256" presetName}.sh"
        (mkPresetScript presetName preset)
    )
    config.t4ko.appPresets;
in {
  options.t4ko.appPresets = lib.mkOption {
    type = lib.types.attrsOf presetType;
    default = {};
    description = "Host-specific presets for launching and arranging applications in Niri.";
  };

  config = {
    assertions =
      lib.mapAttrsToList (name: _: {
        assertion = builtins.match "^[A-Za-z0-9][A-Za-z0-9._ -]*$" name != null;
        message = "t4ko.appPresets preset name '${name}' contains unsupported characters.";
      })
      config.t4ko.appPresets;

    xdg.dataFile = presetScripts;
  };
}
