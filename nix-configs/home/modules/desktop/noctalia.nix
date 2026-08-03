{
  programs.noctalia = {
    enable = true;
    settings = {
      backdrop = {
        enabled = true;
        blur_intensity = 0.6;
        tint_intensity = 0.2;
      };
      bar.default.enabled = false;
      lockscreen.enabled = false;
      notification.enable_daemon = true;
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
