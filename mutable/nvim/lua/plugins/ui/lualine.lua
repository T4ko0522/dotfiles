return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    -- dracula.nvim 提供の lualine テーマを使う。
    -- 注意: テーマ名は 'dracula' ではなく 'dracula-nvim' (公式 README 準拠)。
    -- これでステータスラインのモード色 (Normal=purple 等) が Dracula パレットで揃う。
    opts.options = opts.options or {}
    opts.options.theme = "dracula-nvim"
  end,
}
