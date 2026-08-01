{
  plugins = {
    supermaven = {
      enable = true;
      settings = {
        color = {
          suggestion_color = "#6c7086";
          cterm = 244;
        };
        disable_inline_completion = false;
        disable_keymaps = true;
        ignore_filetypes = {
          TelescopePrompt = true;
          neo-tree = true;
          snacks_picker_input = true;
        };
        log_level = "warn";
      };
    };
  };

  extraConfigLuaPost = ''
    local function supermaven_preview()
      local ok, preview = pcall(require, "supermaven-nvim.completion_preview")
      return ok and preview or nil
    end

    local function accept_supermaven_suggestion()
      local preview = supermaven_preview()
      if preview and preview.has_suggestion() then
        vim.schedule(preview.on_accept_suggestion)
      else
        vim.notify("No Supermaven suggestion", vim.log.levels.WARN)
      end
    end

    local map = vim.keymap.set
    map("i", "<C-l>", accept_supermaven_suggestion, { silent = true, desc = "Accept Supermaven suggestion" })
    map("i", "<C-g>", accept_supermaven_suggestion, { silent = true, desc = "Accept Supermaven suggestion" })
    map("i", "<C-j>", function()
      local preview = supermaven_preview()
      if preview then preview.on_accept_suggestion_word() end
    end, { silent = true, desc = "Accept Supermaven word" })
    map("i", "<C-]>", function()
      local preview = supermaven_preview()
      if preview then preview.on_dispose_inlay() end
    end, { silent = true, desc = "Clear Supermaven suggestion" })

  '';
}
