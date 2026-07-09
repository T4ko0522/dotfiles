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
      -- 背景を不透明にする。wezterm の window_background_opacity=0.7 は
      -- 「デフォルト背景色のセル」だけを透過させ、それ以外の背景色を持つセルは
      -- text_background_opacity (wezterm デフォルト 1.0) で不透明描画される。
      -- Dracula の非デフォルト背景色 (#282A36) で塗るこの設定だけで完結し、
      -- wezterm 側の変更は不要。nvim を開いたペインだけ即座に不透明になり
      -- (ポーリング不要)、分割した隣のシェルペインは透過のまま保てる。
      transparent_bg = false,
      italic_comment = true,
      -- overrides は colors を受け取る関数。Dracula パレットで従来の見た目調整を再現する。
      overrides = function(colors)
        return {
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
