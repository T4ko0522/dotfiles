return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      -- blink.cmp の <Tab> と競合させないため、独自キーに割当
      keymaps = {
        accept_suggestion = "<C-l>", -- Ctrl+L で候補を確定
        accept_word = "<C-j>", -- 1単語だけ確定
        clear_suggestion = "<C-]>", -- 候補を消す
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
      disable_keymaps = false,
    },
  },
}
