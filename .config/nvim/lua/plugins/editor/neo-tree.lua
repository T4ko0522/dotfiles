return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true,
      window = {
        position = "left",
        width = 32,
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_default",
        use_libuv_file_watcher = true,
      },
      event_handlers = {
        -- ファイルを開いたらツリーを自動で閉じる
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close" })
          end,
        },
      },
    },
    init = function()
      -- 起動時にツリーを自動で開く（引数なしの dashboard 表示時は開かない）
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          local file = data.file
          local no_args = file == ""
          local is_directory = vim.fn.isdirectory(file) == 1

          if no_args then
            return -- dashboard を表示させる
          end

          if is_directory then
            vim.cmd.cd(file)
          end

          vim.schedule(function()
            vim.cmd("Neotree show")
            vim.cmd("wincmd p") -- フォーカスを編集バッファ側に戻す
          end)
        end,
      })
    end,
  },
}
