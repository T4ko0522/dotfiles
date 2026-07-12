return {
  "turbio/bracey.vim",
  ft = { "html" },
  cmd = { "Bracey", "BraceyStop", "BraceyReload" },
  build = "npm ci --prefix server",
  init = function()
    vim.g.bracey_auto_start_browser = 1
    vim.g.bracey_refresh_on_save = 1
    vim.g.bracey_server_allow_remote_connections = 0
  end,
}
