{lib, ...}: {
  plugins = {
    compiler.enable = true;
    grug-far.enable = true;
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
    inc-rename.enable = true;
    mini = {
      enable = true;
      modules = {
        ai = {};
        hipatterns = {};
        pairs = {};
        surround = {
          mappings = {
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
    };
    persistence.enable = true;
    rainbow-delimiters.enable = true;
    todo-comments.enable = true;
  };

  extraConfigLuaPost = lib.mkOrder 1120 ''
    vim.o.cursorline = true
    vim.o.number = true
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    require("ufo").setup({
      fold_virt_text_handler = function(virtual_text, start_line, end_line, width, truncate)
        local suffix = (" 󰁂 %d "):format(end_line - start_line)
        local target_width, current_width = width - vim.fn.strdisplaywidth(suffix), 0
        local result = {}
        for _, chunk in ipairs(virtual_text) do
          local text, highlight = chunk[1], chunk[2]
          local text_width = vim.fn.strdisplaywidth(text)
          if target_width > current_width + text_width then
            table.insert(result, chunk)
          else
            text = truncate(text, target_width - current_width)
            table.insert(result, { text, highlight })
            suffix = suffix .. string.rep(" ", math.max(0, target_width - current_width - vim.fn.strdisplaywidth(text)))
            break
          end
          current_width = current_width + text_width
        end
        table.insert(result, { suffix, "MoreMsg" })
        return result
      end,
      provider_selector = function(buffer, filetype)
        if filetype == "markdown" then return markdown_fold_provider end
        return { "treesitter", "indent" }
      end,
    })
  '';
}
