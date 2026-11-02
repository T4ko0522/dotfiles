{
  plugins = {
    flash.enable = true;
    glance.enable = true;
    neo-tree = {
      enable = true;
      settings = {
        close_if_last_window = true;
        filesystem = {
          follow_current_file = {
            enabled = true;
            leave_dirs_open = true;
          };
          filtered_items = {
            visible = true;
            hide_dotfiles = false;
            hide_gitignored = true;
            hide_ignored = false;
            hide_hidden = false;
            never_show = [".DS_Store" "thumbs.db"];
          };
        };
      };
    };
    snacks = {
      enable = true;
      settings = {
        picker = {
          enabled = true;
          actions.__raw = ''require("trouble.sources.snacks").actions'';
        };
        notifier.enabled = true;
        words.enabled = true;
        scroll.enabled = true;
        dim.enabled = true;
        # Existing keymaps use Snacks.terminal rather than ToggleTerm.
        terminal.enabled = true;
      };
    };
    toggleterm.enable = true;
    trouble.enable = true;
    which-key.enable = true;
    # These commands remain the targets of the existing keymaps.
    yazi = {
      enable = true;
      settings = {
        keymaps.show_help = "<f1>";
        open_for_directories = false;
      };
    };
  };
}
