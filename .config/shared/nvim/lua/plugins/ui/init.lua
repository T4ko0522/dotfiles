return {
  -- filename
  {
    "b0o/incline.nvim",
    dependencies = { "catppuccin/nvim" },
    event = "BufReadPre",
    priority = 1200,
    config = function()
      local colors = require("catppuccin.palettes").get_palette("mocha")
      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = colors.mauve, guifg = colors.base },
            InclineNormalNC = { guifg = colors.lavender, guibg = colors.mantle },
          },
        },
        window = { margin = { vertical = 0, horizontal = 1 } },
        hide = {
          cursorline = true,
        },
        render = function(props)
          -- 2つ上の階層までディレクトリを表示
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":p:~:.:h:h")
            .. "/"
            .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if vim.bo[props.buf].modified then
            filename = "[+]" .. filename
          end

          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          return { { icon, guifg = color }, { "" }, { filename } }
        end,
      })
    end,
  },
}
