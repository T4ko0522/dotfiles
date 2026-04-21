return {
  {
    "vim-skk/skkeleton",
    dependencies = { "vim-denops/denops.vim" },
    event = "InsertEnter",
  },
  {
    "delphinus/skkeleton_indicator.nvim",
    dependencies = { "vim-skk/skkeleton" },
    event = "InsertEnter",
    config = true,
  },
}
