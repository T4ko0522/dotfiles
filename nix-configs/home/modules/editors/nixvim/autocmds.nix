{
  extraConfigLuaPost = ''
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = vim.api.nvim_create_augroup("yank_to_clipboard", { clear = true }),
      callback = function()
        if vim.v.event.operator == "y" then vim.fn.setreg("+", vim.fn.getreg('"')) end
      end,
    })

    vim.api.nvim_create_autocmd("QuitPre", {
      callback = function()
        local current = vim.api.nvim_get_current_win()
        for _, window in ipairs(vim.api.nvim_list_wins()) do
          if window ~= current and vim.bo[vim.api.nvim_win_get_buf(window)].buftype == "" then return end
        end
        vim.cmd.only({ bang = true })
      end,
    })

    vim.api.nvim_create_user_command("InsertDatetime", function()
      local row, column = unpack(vim.api.nvim_win_get_cursor(0))
      vim.api.nvim_buf_set_text(0, row - 1, column, row - 1, column, { vim.fn.strftime("%Y-%m-%d %H:%M:%S") })
    end, {})

    vim.api.nvim_create_user_command("CountCleanTextLength", function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local text = table.concat(lines, "\n")
      text = text:gsub("```.-```", ""):gsub("`.-`", ""):gsub("%[%^%d+%]", "")
      text = text:gsub("\n%[%^%d+%]:[^\n]*", ""):gsub("<https?://[^>]+>", "")
      text = text:gsub("%[([^%]]-)%]%([^%)]+%)", "%1")
      text = text:gsub("#+", ""):gsub("%*%*", ""):gsub("%*", ""):gsub("_", ""):gsub("[%[%]%(%)]", ""):gsub("-", "")
      print("ファイル全体の文字数（記法除去後）: " .. vim.fn.strchars(text:gsub("%s+", "")))
    end, {})

    vim.api.nvim_create_user_command("CoAuthoredBy", function(command)
      if command.args == "" then
        vim.notify("Usage: :CoAuthoredBy <github-username>", vim.log.levels.ERROR)
        return
      end
      vim.system({
        "gh", "api", "/users/" .. command.args, "-q",
        "\"Co-Authored-By: \\(.name) <\\(.id)+\\(.login)@users.noreply.github.com>\"",
      }, { text = true, timeout = 10000 }, function(result)
        vim.schedule(function()
          if result.code ~= 0 then
            vim.notify("Failed to get GitHub user: " .. (result.stderr or ""), vim.log.levels.ERROR)
            return
          end
          vim.api.nvim_put({ result.stdout:gsub("\n$", "") }, "l", true, true)
        end)
      end)
    end, { nargs = 1, desc = "Insert a Co-Authored-By trailer" })
  '';
}
