return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  -- NixOS ではプリビルドバイナリ (動的リンク) が動かないため、node 実行用に依存だけ入れる。
  -- bin/ を消しておかないと executable() 判定でプリビルド側が優先される (autoload/mkdp/rpc.vim)。
  build = "cd app && rm -rf bin && yarn install --frozen-lockfile",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    vim.g.mkdp_auto_close = 0
    vim.g.mkdp_theme = "dark"
    vim.g.mkdp_browser = ""
    vim.g.mkdp_open_to_the_world = 0
    vim.g.mkdp_combine_preview = 0
    vim.g.mkdp_combine_preview_auto_refresh = 1

    local function toggle()
      vim.cmd("MarkdownPreviewToggle")
    end
    -- leader 経由のフォールバック
    vim.keymap.set("n", "<leader>mp", toggle, { desc = "Markdown Preview (browser)" })
  end,
}
