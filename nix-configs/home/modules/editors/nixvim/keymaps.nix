{
  extraConfigLuaPost = ''
    local map = vim.keymap.set
    local silent = { noremap = true, silent = true }

    map({ "n", "x", "o" }, ";,", ",", { desc = "Repeat f/F/t/T in reverse" })
    map({ "n", "v" }, "p", '"+p', silent)
    map({ "n", "v" }, "P", '"+P', silent)
    map("i", "<C-a>", "<Home>", silent)
    map("i", "<C-e>", "<End>", silent)
    map("n", "<C-i>", "<C-i>", silent)
    map("i", "<C-i>", "<C-i>", silent)

    map("n", "+", "<C-a>", silent)
    map("n", "-", "<C-x>", silent)
    map("n", "<Tab>", ":tabnext<CR>", silent)
    map("n", "<S-Tab>", ":tabprevious<CR>", silent)
    map("n", "ss", ":split<CR>", silent)
    map("n", "sv", ":vsplit<CR>", silent)
    map("n", "sh", "<C-w>h", silent)
    map("n", "sk", "<C-w>k", silent)
    map("n", "sj", "<C-w>j", silent)
    map("n", "sl", "<C-w>l", silent)
    map("n", "<C-w><Left>", "<C-w><", silent)
    map("n", "<C-w><Right>", "<C-w>>", silent)
    map("n", "<C-w><Up>", "<C-w>+", silent)
    map("n", "<C-w><Down>", "<C-w>-", silent)
    map("n", "<C-j>", function() vim.diagnostic.jump({ count = 1 }) end, { noremap = true, silent = true, desc = "Next diagnostic" })

    map({ "n", "x" }, "<A-h>", "10h", { desc = "Move 10 chars left" })
    map({ "n", "x" }, "<A-j>", "10j", { desc = "Move 10 lines down" })
    map({ "n", "x" }, "<A-k>", "10k", { desc = "Move 10 lines up" })
    map({ "n", "x" }, "<A-l>", "10l", { desc = "Move 10 chars right" })

    local function git_root()
      local buffer_name = vim.api.nvim_buf_get_name(0)
      local buffer_dir = buffer_name == "" and vim.fn.getcwd() or vim.fn.fnamemodify(buffer_name, ":h")
      local result = vim.system({ "git", "-C", buffer_dir, "rev-parse", "--show-toplevel" }, { text = true, timeout = 3000 }):wait()
      return result.code == 0 and vim.trim(result.stdout) or vim.fn.getcwd()
    end

    map("n", "<C-/>", function() Snacks.terminal() end, { desc = "Terminal" })
    map("n", "<C-_>", function() Snacks.terminal(nil, { cwd = git_root() }) end, { desc = "Terminal (project root)" })
    map("n", "<leader>nn", function() Snacks.notifier.show_history() end, { desc = "Notification history" })
    map("n", "<leader>gg", function() Snacks.lazygit({ cwd = vim.fn.getcwd() }) end, { desc = "LazyGit (cwd)" })
    map("n", "<leader>gG", function() Snacks.lazygit({ cwd = git_root() }) end, { desc = "LazyGit (project root)" })
    map("n", "<leader><leader>", function() Snacks.picker.files({ cwd = git_root(), hidden = git_root():match("dotfiles$") ~= nil }) end, { desc = "Find files" })
    map("n", "<leader>/", function() Snacks.picker.grep({ cwd = git_root(), hidden = git_root():match("dotfiles$") ~= nil }) end, { desc = "Grep" })
    map("n", "<leader>p", function() Snacks.picker.pickers() end, { desc = "Pickers" })
    map("n", "<leader>y", "<cmd>Yazi<CR>", { desc = "Open Yazi" })
    map("n", "<leader>P", "<cmd>PasteImage<CR>", { desc = "Paste image" })
    map({ "n", "v" }, "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, { desc = "Format buffer" })
    map({ "n", "i" }, "<F24>", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown preview" })
    map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Open diff view" })
    map("n", "<leader>gD", "<cmd>DiffviewClose<CR>", { desc = "Close diff view" })
    map("n", "<leader>gl", "<cmd>DiffviewFileHistory<CR>", { desc = "Git history" })
    map("n", "<leader>gL", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history" })
    map("n", "<leader>uC", function() require("treesitter-context").toggle() end, { desc = "Toggle Treesitter context" })
    map("n", "[c", function() require("treesitter-context").go_to_context(vim.v.count1) end, { desc = "Jump to upper context" })
    map("n", "zR", function() require("ufo").openAllFolds() end, { desc = "Open all folds" })
    map("n", "zM", function() require("ufo").closeAllFolds() end, { desc = "Close all folds" })
    map("n", "K", function()
      if not require("ufo").peekFoldedLinesUnderCursor() then vim.lsp.buf.hover() end
    end, { desc = "Peek fold or hover" })
    map({ "n", "v" }, "<leader>wr", "<cmd>WinResizerStartResize<CR>", { desc = "Resize window" })
    map({ "n", "v" }, "<C-w>r", "<cmd>WinResizerStartResize<CR>", { desc = "Resize window" })

    map("n", "gh", function()
      local target = vim.fn.expand("<cfile>")
      if target:match("^https?://") then vim.ui.open(target) else vim.cmd("normal! gF") end
    end, { desc = "Open link or file" })
    map("n", "gx", function()
      local word = vim.fn.expand("<cWORD>")
      local arn = word:match("[\"`']?(arn:aws[a-z%-]*:[^\"`'%s]+)[\"`']?")
      vim.ui.open(arn and "https://console.aws.amazon.com/go/view?arn=" .. arn or vim.fn.expand("<cfile>"))
    end, { desc = "Open URL or AWS ARN" })
    map("n", "<leader>gR", function()
      local repository = vim.fn.expand("<cfile>")
      if repository:match(".+/[^/]+") then vim.ui.open("https://github.com/" .. repository) else vim.cmd("normal! gF") end
    end, { desc = "Open GitHub repository" })
    map("n", "#", function()
      vim.api.nvim_feedkeys(":%s/" .. vim.fn.expand("<cword>") .. "//g", "n", false)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Left><Left>", true, true, true), "n", false)
      vim.opt.hlsearch = true
    end, { desc = "Substitute word under cursor" })

    local scroll_cycle = { position = 0, at = 0 }
    map("n", "zz", function()
      scroll_cycle.position, scroll_cycle.at = 1, vim.uv.now()
      vim.cmd("normal! zz")
    end, { desc = "Scroll center" })
    map("n", "z", function()
      if scroll_cycle.position > 0 and vim.uv.now() - scroll_cycle.at < 1000 then
        scroll_cycle.at = vim.uv.now()
        scroll_cycle.position = scroll_cycle.position % 3 + 1
        vim.cmd("normal! " .. ({ "zz", "zt", "zb" })[scroll_cycle.position])
      else
        scroll_cycle.position = 0
        vim.cmd("normal! z" .. vim.fn.getcharstr())
      end
    end, { desc = "Cycle scroll position" })
  '';
}
