return {
  "toppair/peek.nvim",
  build = "deno task --quiet build:fast",
  cmd = { "PeekOpen", "PeekClose", "PeekToggle" },
  keys = {
    { "<leader>mp", "<cmd>PeekToggle<CR>", desc = "Markdown Preview (peek)", ft = "markdown" },
    { "<C-S-v>", "<cmd>PeekToggle<CR>", desc = "Markdown Preview (peek)", ft = "markdown", mode = { "n", "i" } },
  },
  config = function()
    local peek = require("peek")
    peek.setup({
      auto_load = true,
      close_on_bdelete = true,
      syntax = true,
      theme = "dark",
      update_on_change = true,
      app = "browser", -- "webview" だと WebView2 依存。"browser" は既定ブラウザで開く
      filetype = { "markdown" },
      throttle_at = 200000,
      throttle_time = "auto",
    })
    vim.api.nvim_create_user_command("PeekOpen", peek.open, {})
    vim.api.nvim_create_user_command("PeekClose", peek.close, {})
    vim.api.nvim_create_user_command("PeekToggle", function()
      if peek.is_open() then
        peek.close()
      else
        peek.open()
      end
    end, {})
  end,
}
