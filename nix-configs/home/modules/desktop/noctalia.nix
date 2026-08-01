{
  programs.noctalia = {
    enable = true;
    settings = {
      bar.default.enabled = false;
      lockscreen.enabled = false;
      notification.enable_daemon = false;
      shell = {
        setup_wizard_enabled = false;
        panel = {
          control_center_placement = "floating";
          control_center_position = "top_right";
        };
      };
      wallpaper.enabled = false;
    };
  };
}
