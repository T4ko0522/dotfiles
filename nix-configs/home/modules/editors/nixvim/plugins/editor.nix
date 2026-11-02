{
  plugins = {
    comment.enable = true;
    emmet.enable = true;
    img-clip = {
      enable = true;
      settings.default = {
        dir_path = "assets";
        extension = "png";
        prompt_for_file_name = true;
        relative_to_current_file = true;
        show_dir_path_in_prompt = false;
        use_absolute_path = false;
      };
    };
    lsp-signature = {
      enable = true;
      settings = {
        hint_enable = true;
        hint_prefix = " ";
        floating_window = true;
        bind = true;
      };
    };
    # Keep the existing gsa/gsd/gsf/gsF/gsh/gsr/gsn surround keys.
    mini = {
      enable = true;
      modules = {
        ai = {};
        surround.mappings = {
          add = "gsa";
          delete = "gsd";
          find = "gsf";
          find_left = "gsF";
          highlight = "gsh";
          replace = "gsr";
          update_n_lines = "gsn";
        };
      };
    };
    nvim-autopairs.enable = true;
    spectre.enable = true;
    todo-comments.enable = true;
  };

  extraConfigLuaPost = ''
    vim.g.user_emmet_leader_key = "<C-y>"
    vim.g.user_emmet_settings = { variables = { lang = "ja" } }
    require("ufo").setup({
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    })
  '';
}
