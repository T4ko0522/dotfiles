return {
  {
    "Mofiqul/dracula.nvim",
    lazy = false, -- colorscheme として最優先で読み込む
    priority = 1000,
    -- colorscheme の適用自体は LazyVim (config/lazy.lua の opts.colorscheme = "dracula") が
    -- 起動時に行う。ここでは setup でパレット/透過/オーバーライドを確定させるだけ。
    -- dracula.nvim は本体同梱ではなくプラグイン提供なので、catppuccin 同梱版のような
    -- runtimepath 競合 (custom_highlights が上書きされる問題) は起きない。
    opts = {
      transparent_bg = true, -- 背景透過 (従来の catppuccin transparent_groups を踏襲)
      italic_comment = true,
      -- overrides は colors を受け取る関数。Dracula パレットで従来の見た目調整を再現する。
      overrides = function(colors)
        return {
          -- 透過: transparent_bg が拾わない Snacks / フロート系を明示的に NONE 化
          NormalFloat = { bg = "NONE" },
          FloatBorder = { fg = colors.comment, bg = "NONE" },
          SnacksBackdrop = { bg = "NONE" },
          SnacksNormal = { bg = "NONE" },
          SnacksNormalNC = { bg = "NONE" },
          -- 行番号: Dracula 既定 (gutter_fg=#4B5263) は暗いので白寄りに持ち上げ、
          -- カーソル行は purple で強調 (従来 lavender 強調の踏襲)。
          -- modicator が Normal モード時に CursorLineNr を継承する。
          LineNr = { fg = colors.white },
          LineNrAbove = { fg = colors.white },
          LineNrBelow = { fg = colors.white },
          CursorLineNr = { fg = colors.purple, bold = true },
        }
      end,
    },
    config = function(_, opts)
      require("dracula").setup(opts)
    end,
  },
}
