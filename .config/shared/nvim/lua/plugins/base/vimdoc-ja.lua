return {
  "vim-jp/vimdoc-ja",
  -- lazy = true,
  keys = {
    { "h", mode = "c" },
  },
  -- :helptags が doc/tags-ja の `!_TAG_FILE_ENCODING` 行を剥がしてしまい
  -- :Lazy update が "local changes" で落ちるため、生成後に tracked file を戻す。
  build = function(plugin)
    vim.fn.system({ "git", "-C", plugin.dir, "update-index", "--no-skip-worktree", "doc/tags-ja" })
    vim.fn.system({ "git", "-C", plugin.dir, "checkout", "--", "doc/tags-ja" })
  end,
}
