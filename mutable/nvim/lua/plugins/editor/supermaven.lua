return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = nil,
        accept_word = nil,
        clear_suggestion = nil,
      },
      ignore_filetypes = {
        TelescopePrompt = true,
        ["neo-tree"] = true,
        ["snacks_picker_input"] = true,
      },
      -- Catppuccin Mocha overlay0 でゴーストテキストを描画
      color = {
        suggestion_color = "#6c7086",
        cterm = 244,
      },
      log_level = "warn",
      disable_inline_completion = false,
      disable_keymaps = true,
    },
  },
}
