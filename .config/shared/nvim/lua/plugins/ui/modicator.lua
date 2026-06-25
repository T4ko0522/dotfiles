return {
  {
    "mawkler/modicator.nvim",
    dependencies = { "Mofiqul/dracula.nvim" },
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
      -- lualine integration を切る: 有効だと lualine の mode_section の色を取りに行くが
      -- タイミング次第で Normal モード時に暗い色を引いてしまう。OFF にすると Normal は
      -- CursorLineNr (dracula.lua の overrides で purple=#BD93F9 に固定) を継承し、
      -- Insert/Visual/Replace 等は Question/String/WarningMsg にフォールバックリンクされ
      -- Dracula パレット由来の明るい色が自動的に適用される。
      integration = {
        lualine = {
          enabled = false,
        },
      },
    },
  },
}
