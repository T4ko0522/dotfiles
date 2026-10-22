{
  config,
  homeDirectory,
  lib,
  pkgs,
  ...
}: let
  root = "${homeDirectory}/Project/github.com/T4ko0522/irodori-interface";
  data = "${root}/data";
  tunnelId = "adc2a5b7-8bc9-4167-8b0d-de3bd0eb86fb";
in {
  home.activation.createIrodoriLogs = lib.hm.dag.entryBetween ["setupLaunchAgents"] ["writeBoundary"] ''
    run mkdir -p ${lib.escapeShellArg "${data}/logs"}
  '';

  home.file.".cloudflared/irodori.yml".text = ''
    tunnel: ${tunnelId}
    credentials-file: ${homeDirectory}/.cloudflared/${tunnelId}.json
    ingress:
      - hostname: api.t4ko.com
        service: http://127.0.0.1:8080
      - service: http_status:404
  '';

  launchd.agents = {
    irodori-worker = {
      enable = true;
      config = {
        Label = "local.irodori.worker";
        ProgramArguments = [
          "${config.nix.package}/bin/nix"
          "develop"
          root
          "--command"
          "uv"
          "run"
          "--locked"
          "--extra"
          "inference"
          "python"
          "-m"
          "irodori_worker"
          "--data-dir"
          data
          "--socket"
          "${data}/worker.sock"
          "--models"
          "${root}/models"
        ];
        EnvironmentVariables = {
          HF_HUB_OFFLINE = "1";
          TRANSFORMERS_OFFLINE = "1";
          PYTHONUNBUFFERED = "1";
        };
        WorkingDirectory = root;
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        ProcessType = "Background";
        StandardOutPath = "${data}/logs/worker.log";
        StandardErrorPath = "${data}/logs/worker.error.log";
      };
    };
    irodori-api = {
      enable = true;
      config = {
        Label = "local.irodori.api";
        ProgramArguments = [
          "${root}/bin/irodori"
          "serve"
          "--data-dir"
          data
          "--socket"
          "${data}/worker.sock"
          "--authority"
          "api.t4ko.com"
          "--cors-origins"
          ""
        ];
        WorkingDirectory = root;
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        ProcessType = "Background";
        StandardOutPath = "${data}/logs/api.log";
        StandardErrorPath = "${data}/logs/api.error.log";
      };
    };
    irodori-cloudflared = {
      enable = true;
      config = {
        Label = "local.irodori.cloudflared";
        ProgramArguments = [
          "${pkgs.cloudflared}/bin/cloudflared"
          "tunnel"
          "--config"
          "${homeDirectory}/.cloudflared/irodori.yml"
          "run"
        ];
        WorkingDirectory = root;
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        ProcessType = "Background";
        StandardOutPath = "${data}/logs/cloudflared.log";
        StandardErrorPath = "${data}/logs/cloudflared.error.log";
      };
    };
  };
}
