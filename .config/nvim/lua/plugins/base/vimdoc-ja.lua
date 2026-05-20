return {
  "vim-jp/vimdoc-ja",
  -- lazy = true,
  keys = {
    { "h", mode = "c" },
  },
  -- :helptags が doc/tags-ja の `!_TAG_FILE_ENCODING` 行を剥がしてしまい
  -- :Lazy update が "local changes" で落ちるため、git 側で変更を無視させる。
  build = function(plugin)
    vim.fn.system({ "git", "-C", plugin.dir, "update-index", "--skip-worktree", "doc/tags-ja" })
  end,
}
