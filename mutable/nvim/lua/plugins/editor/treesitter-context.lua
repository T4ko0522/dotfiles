return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>uC",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "Toggle Treesitter Context",
      },
      {
        "[c",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Jump to upper context",
      },
    },
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 20,
      multiline_threshold = 1,
      trim_scope = "outer",
      mode = "cursor",
      separator = nil,
      zindex = 20,
    },
  },
}
