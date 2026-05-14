return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeStatus",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
    },
    opts = {
      -- claude CLI のパスを自動検出。明示指定したい場合は terminal_cmd = "claude"
    },
    keys = {
      { "<leader>a", "", desc = "+ai (claude)" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude session" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude session" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeSend<cr>",
        mode = "v",
        desc = "Send selection to Claude",
      },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file from neo-tree",
        ft = { "neo-tree", "NvimTree" },
      },
      -- Claude が提示した差分を承認/拒否
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
    },
  },
}
