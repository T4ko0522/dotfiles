-- 未使用 provider を無効化（起動時の `has("python3")` 等の探索コストを削減）
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
-- python は遅延で解決（必要になったタイミングで exepath を呼ぶ）
vim.g.loaded_python3_provider = nil
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  once = true,
  callback = function()
    vim.schedule(function()
      local py = vim.fn.exepath("python3")
      if py == "" then
        py = vim.fn.exepath("python")
      end
      if py ~= "" then
        vim.g.python3_host_prog = py
      end
    end)
  end,
})

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
