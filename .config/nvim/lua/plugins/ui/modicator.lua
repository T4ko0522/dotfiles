return {
  {
    "mawkler/modicator.nvim",
    dependencies = { "catppuccin/nvim" },
    event = "VeryLazy",
    init = function()
      -- modicator は cursorline / number / termguicolors を要求する
      vim.o.cursorline = true
      vim.o.number = true
      vim.o.termguicolors = true
    end,
    opts = {
      show_warnings = false,
      highlights = {
        defaults = { bold = true },
      },
      integration = {
        lualine = {
          enabled = true,
          mode_section = "a",
        },
      },
    },
  },
}
