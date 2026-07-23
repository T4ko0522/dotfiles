return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    opts.options = opts.options or {}

    -- アクティブタブを Dracula の purple で強調。
    -- colorscheme が dracula のとき LazyVim の catppuccin 統合 (opts.highlights を
    -- 関数で渡してくる) は発火しないため、opts.highlights は nil/table のみ。
    -- table 同士で安全に merge できる。
    local ok, dracula = pcall(require, "dracula")
    if not ok then
      return
    end
    local c = dracula.colors()
    opts.highlights = vim.tbl_deep_extend("force", opts.highlights or {}, {
      buffer_selected = { fg = c.purple, bold = true },
      indicator_selected = { fg = c.purple },
      numbers_selected = { fg = c.purple, bold = true },
      tab_selected = { fg = c.purple },
    })
  end,
}
