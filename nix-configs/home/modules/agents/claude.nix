{
  config,
  lib,
  ...
}: let
  baseSettings = builtins.fromJSON (builtins.readFile ./files/claude/claude-settings-base.json);
  notificationHooks = builtins.fromJSON (builtins.readFile ./files/claude/claude-settings-nixos-hooks.json);
in {
  options.t4ko.claude.notifications.enable = lib.mkEnableOption "Claude Code desktop notifications";

  config.home.file =
    {
      ".claude/CLAUDE.md".source = ./files/claude/CLAUDE.md;
      ".claude/agents".source = ./files/claude/agents;
      ".claude/claude-icon.svg".source = ./files/claude/claude-icon.svg;
      ".claude/settings.json".text = builtins.toJSON (
        baseSettings
        // lib.optionalAttrs config.t4ko.claude.notifications.enable notificationHooks
      );
      ".claude/statusline.sh" = {
        source = ./files/claude/executable_statusline.sh;
        executable = true;
      };
    }
    // lib.optionalAttrs config.t4ko.claude.notifications.enable {
      ".claude/claude-notify-hook.sh" = {
        source = ./files/claude/claude-notify-hook.sh;
        executable = true;
      };
    };
}
