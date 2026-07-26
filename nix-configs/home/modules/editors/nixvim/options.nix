{
  globals = {
    mapleader = ",";
    maplocalleader = "\\";
    ai_cmp = false;
    loaded_ruby_provider = 0;
    loaded_perl_provider = 0;
    loaded_node_provider = 0;

    terminal_color_0 = "#45475a";
    terminal_color_1 = "#f38ba8";
    terminal_color_2 = "#a6e3a1";
    terminal_color_3 = "#f9e2af";
    terminal_color_4 = "#89b4fa";
    terminal_color_5 = "#f5c2e7";
    terminal_color_6 = "#94e2d5";
    terminal_color_7 = "#bac2de";
    terminal_color_8 = "#585b70";
    terminal_color_9 = "#f38ba8";
    terminal_color_10 = "#a6e3a1";
    terminal_color_11 = "#f9e2af";
    terminal_color_12 = "#89b4fa";
    terminal_color_13 = "#f5c2e7";
    terminal_color_14 = "#94e2d5";
    terminal_color_15 = "#a6adc8";
  };

  opts = {
    clipboard = "";
    helplang = ["ja"];
    pumblend = 10;
    spelllang = ["en" "cjk"];
    splitbelow = true;
    splitright = true;
    termguicolors = true;
    whichwrap = "b,s,h,l,<,>,[,],~";
    winblend = 20;
  };

  extraConfigLuaPost = ''
    vim.api.nvim_set_hl(0, "ActiveWindowSeparator", { fg = "#69F5CD" })
    vim.api.nvim_set_hl(0, "InactiveWindowSeparator", { fg = "#555555" })
    vim.api.nvim_set_hl(0, "SpellCap", {})

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "SpellCap", {})
      end,
    })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
      callback = function()
        vim.opt.winblend = 0
      end,
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
      callback = function()
        vim.opt.winblend = 20
      end,
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
      callback = function()
        vim.wo.winhighlight = "WinSeparator:ActiveWindowSeparator"
      end,
    })

    vim.api.nvim_create_autocmd("WinLeave", {
      callback = function()
        vim.wo.winhighlight = ""
      end,
    })

    vim.cmd("cabbrev H belowright vertical help")
  '';
}
