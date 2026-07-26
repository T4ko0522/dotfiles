-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- octo.nvim: octo://バッファでスワップファイルを無効化（E325: ATTENTION対策）
-- BufNew: バッファ名が設定された直後（nvim_buf_set_nameのタイミング）に発火
vim.api.nvim_create_autocmd({ "BufNew", "BufAdd", "BufWinEnter" }, {
  pattern = "octo://*",
  callback = function()
    vim.opt_local.swapfile = false
  end,
})

-- SpellCap（青い波線）を無効化
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "SpellCap", {})
  end,
})
vim.api.nvim_set_hl(0, "SpellCap", {})

-- 背景は dracula.nvim の setup (plugins/ui/dracula.lua の transparent_bg = false)
-- で不透明にする。wezterm デフォルトの text_background_opacity=1.0 により nvim
-- ペインだけ不透明描画され、シェルペインは透過のまま保たれる (wezterm 側の設定は
-- 不要)。autocmds.lua は VeryLazy 読込で colorscheme 適用後となり ColorScheme
-- イベントを取り逃すため、背景設定はここには置かない。

vim.api.nvim_create_user_command("CountCleanTextLength", function()
  local bufnr = 0
  local mode = vim.fn.mode()
  local lines = {}
  local context = ""

  if mode == "v" or mode == "V" or mode == "\22" then
    -- 選択範囲取得
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_row = start_pos[2] - 1
    local start_col = start_pos[3] - 1
    local end_row = end_pos[2] - 1
    local end_col = end_pos[3]

    lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
    context = "選択範囲"
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    context = "ファイル全体"
  end

  local text = table.concat(lines, "\n")

  -- Markdownの記法など除去
  text = text:gsub("```.-```", "")
  text = text:gsub("`.-`", "")
  text = text:gsub("%[%^%d+%]", "")
  text = text:gsub("\n%[%^%d+%]:[^\n]*", "")
  text = text:gsub("<https?://[^>]+>", "")
  text = text:gsub("%[([^%]]-)%]%([^%)]+%)", "%1")
  text = text:gsub("#+", ""):gsub("%*%*", ""):gsub("%*", ""):gsub("_", ""):gsub("[%[%]%(%)]", ""):gsub("-", "")

  local clean = text:gsub("%s+", "")
  print(context .. "の文字数（記法除去後）: " .. #clean)
end, {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set({ "n", "v" }, "<leader>mc", "<cmd>CountCleanTextLength<CR>", {
      desc = "🧮 Markdown文字数カウント",
      buffer = true,
    })
    vim.keymap.set("n", "so", "<cmd>Arto<CR>", {
      desc = "Open file in Arto",
      buffer = true,
    })
  end,
})

vim.api.nvim_create_user_command("InsertDatetime", function()
  -- io.popen('date ...') の代わりに vim.fn.strftime を使用（外部プロセス不要）
  local result = vim.fn.strftime("%Y-%m-%d %H:%M:%S")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Lua は 0-indexed
  vim.api.nvim_buf_set_text(0, row, col, row, col, { result })
end, {})

-- ヤンク時のみクリップボード連携（削除などは除外）
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_to_clipboard", { clear = true }),
  callback = function()
    if vim.v.event.operator == "y" then
      vim.fn.setreg("+", vim.fn.getreg('"'))
    end
  end,
})

-- :quit時に特殊ウィンドウ(quickfix, help等)のみが残っている場合は自動で閉じる
-- ref: https://vim-jp.org/docs/
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= current_win then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "" then
          return
        end
      end
    end
    vim.cmd.only({ bang = true })
  end,
})

-- Generate Co-Authored-By trailer and insert at cursor position
-- Usage: :CoAuthoredBy <github-username>
vim.api.nvim_create_user_command("CoAuthoredBy", function(opts)
  local username = opts.args
  if username == "" then
    vim.notify("Usage: :CoAuthoredBy <github-username>", vim.log.levels.ERROR)
    return
  end

  local cmd = string.format(
    [[gh api /users/%s -q '"Co-Authored-By: \(.name) <\(.id)+\(.login)@users.noreply.github.com>"']],
    username
  )
  -- 非同期実行（GitHub API呼び出しのフリーズ防止、タイムアウト10秒）
  vim.notify("Fetching user info for " .. username .. "...", vim.log.levels.INFO)
  vim.system({ "sh", "-c", cmd }, { text = true, timeout = 10000 }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("Failed to get user info: " .. (result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      local text = result.stdout:gsub("\n$", "")
      vim.api.nvim_put({ text }, "l", true, true)
      vim.notify("Inserted: " .. text, vim.log.levels.INFO)
    end)
  end)
end, {
  nargs = 1,
  desc = "Generate Co-Authored-By trailer from GitHub username",
})

-- Open file in Arto (markdown editor)
vim.api.nvim_create_user_command("Arto", function(opts)
  local path = opts.args ~= "" and vim.fn.fnamemodify(opts.args, ":p") or vim.fn.expand("%:p")
  vim.system({ "open", "-a", "Arto", path })
end, {
  nargs = "?",
  complete = "file",
  desc = "Open file in Arto",
})
