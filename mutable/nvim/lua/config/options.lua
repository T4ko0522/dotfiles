-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Leader キーをカンマに変更（プラグイン読み込み前に設定する必要がある）
-- ノーマルモードの `,` (f/t の逆方向リピート) は失われるため、代替として ";," を割当
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"
-- Supermaven は blink.cmp の menu source ではなく inline ghost text として使う
vim.g.ai_cmp = false
vim.keymap.set({ "n", "x", "o" }, ";,", ",", { desc = "Repeat f/F/t/T (reverse)" })

-- クリップボード連携を無効化（TextYankPostでヤンク時のみ連携する）
-- LazyVimのデフォルト: vim.opt.clipboard = "unnamedplus"
vim.opt.clipboard = ""

-- 編集中のファイルパスを右上に表示
-- vim.opt.winbar = "%=%m %f"
-- vim標準スペルチェックから日本語を除外
vim.opt.spelllang:append("cjk")
-- スペル辞書の設定（dotfiles管理 + ローカル専用）
-- zg: dotfiles管理の辞書、2zg: ローカル専用の辞書
vim.opt.spellfile = {
  vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
  vim.fn.stdpath("data") .. "/spell/local.utf-8.add",
}

-- Enable this option to avoid conflicts with Prettier.
vim.g.lazyvim_prettier_needs_config = true

--
-- Window
--
-- open window at right side when vertical split
vim.opt.splitright = true
-- open window at bottom side when horizontal split
vim.opt.splitbelow = true

--
-- Help
--
vim.opt.helplang = "ja"
-- Create a command-line abbreviation for 'H' to open help in a vertical split on the right
vim.cmd("cabbrev H belowright vertical help")

vim.opt.termguicolors = true

-- 初期状態で floating window の透過を有効にする
vim.opt.winblend = 20
-- コマンドラインモードに入ったときに透過を無効にする
vim.api.nvim_create_autocmd("CmdlineEnter", {
  callback = function()
    vim.opt.winblend = 0 -- 透過効果を無効にする
  end,
})
-- コマンドラインモードを終了したときに透過を再び有効にする
vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function()
    vim.opt.winblend = 20 -- 透過効果を再び有効にする
  end,
})

-- 補完メニューの背景透過（低めに設定して視認性を確保）
vim.opt.pumblend = 10

-- アクティブウィンドウの枠線の色を設定
vim.cmd([[
  hi ActiveWindowSeparator guifg=#69F5CD
  hi InactiveWindowSeparator guifg=#555555
]])

-- アクティブウィンドウの枠線を変える
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  callback = function()
    vim.wo.winhighlight = "WinSeparator:ActiveWindowSeparator"
  end,
})

-- 非アクティブウィンドウの枠線を変える
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    -- NeoTreeの場合は変更しない
    local filetype = vim.bo.filetype
    if filetype ~= "neo-tree" then
      vim.wo.winhighlight = ""
    end
  end,
})
vim.opt.whichwrap = "b,s,h,l,<,>,[,],~"

-- Terminal colors (Catppuccin Mocha)
-- WezTerm の :terminal でカラーパレットを一致させる
-- ANSI colors (0-7)
vim.g.terminal_color_0 = "#45475a" -- black (surface1)
vim.g.terminal_color_1 = "#f38ba8" -- red
vim.g.terminal_color_2 = "#a6e3a1" -- green
vim.g.terminal_color_3 = "#f9e2af" -- yellow
vim.g.terminal_color_4 = "#89b4fa" -- blue
vim.g.terminal_color_5 = "#f5c2e7" -- magenta (pink)
vim.g.terminal_color_6 = "#94e2d5" -- cyan (teal)
vim.g.terminal_color_7 = "#bac2de" -- white (subtext1)
-- Bright colors (8-15)
vim.g.terminal_color_8 = "#585b70" -- bright black (surface2)
vim.g.terminal_color_9 = "#f38ba8" -- bright red
vim.g.terminal_color_10 = "#a6e3a1" -- bright green
vim.g.terminal_color_11 = "#f9e2af" -- bright yellow
vim.g.terminal_color_12 = "#89b4fa" -- bright blue
vim.g.terminal_color_13 = "#f5c2e7" -- bright magenta (pink)
vim.g.terminal_color_14 = "#94e2d5" -- bright cyan (teal)
vim.g.terminal_color_15 = "#a6adc8" -- bright white (subtext0)
