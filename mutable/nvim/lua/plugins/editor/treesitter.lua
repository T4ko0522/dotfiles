return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- LazyVim デフォルトの ensure_installed に css/scss は無く、main ブランチには
    -- auto_install も無いため、ここに列挙した言語だけがインストールされる。
    -- 扱う filetype が増えたらここへ追記すること。
    opts = {
      ensure_installed = { "css", "scss" },
    },
  },
}
