return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      require("nvim-treesitter.install").compilers = { "zig", "gcc", "clang", "cl", "cc" }
      return opts
    end,
  },
}
