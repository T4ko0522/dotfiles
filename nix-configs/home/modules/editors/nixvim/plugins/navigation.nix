{
  plugins = {
    flash.enable = true;
    snacks = {
      enable = true;
      settings = {
        image = {
          doc = {
            enabled = true;
            inline = true;
            max_height = 40;
            max_width = 80;
          };
          enabled = true;
        };
        scroll.enabled = false;
      };
    };
    trouble.enable = true;
    which-key.enable = true;
    yazi = {
      enable = true;
      settings = {
        keymaps.show_help = "<f1>";
        open_for_directories = false;
      };
    };
  };
}
