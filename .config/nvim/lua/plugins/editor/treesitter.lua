return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      require("nvim-treesitter.install").compilers = { "gcc", "zig", "clang", "cl", "cc" }
      return opts
    end,
  },
}
