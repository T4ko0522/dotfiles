return {
  {
    "catppuccin/nvim",
    lazy = false, -- colorscheme として最優先で読み込む
    priority = 1000,
    name = "catppuccin",
    -- 透過背景 / 行番号オーバーライドは catppuccin の :colorscheme より前に autocmd を
    -- 仕込んでおく必要があるため init (= setup より前) で登録する。
    -- VeryLazy の autocmds.lua では遅すぎて ColorScheme イベントを取り逃すため、ここに置く。
    --
    -- 重要: Neovim 2026-01-31 以降、本体 (`$VIMRUNTIME/colors/catppuccin.vim`) に
    -- 公式同梱の catppuccin colorscheme が含まれている。`:colorscheme catppuccin` を
    -- 実行すると runtimepath 順で本体側が優先 source され、`catppuccin/nvim` プラグインの
    -- `custom_highlights` が完全に上書きされる (例: LineNr が surface1=#45475a に戻る)。
    -- 同梱版に触らずに済むよう ColorScheme 発火後に強制再上書きする。
    init = function()
      local transparent_groups = {
        "Normal",
        "NormalNC",
        "NormalFloat",
        "FloatBorder",
        "VertSplit",
        "SnacksBackdrop",
        "SnacksNormal",
        "SnacksNormalNC",
      }
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("catppuccin_overrides", { clear = true }),
        callback = function()
          for _, g in ipairs(transparent_groups) do
            vim.api.nvim_set_hl(0, g, { bg = "NONE", ctermbg = "NONE" })
          end
          -- 行番号: 同梱 catppuccin.vim が LineNr=#45475a を強制してくるので再上書き
          -- Mocha パレット準拠 — 通常行は text、カーソル行は lavender (公式推奨)
          vim.api.nvim_set_hl(0, "LineNr", { fg = "#cdd6f4" })
          vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#cdd6f4" })
          vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#cdd6f4" })
          vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#b4befe", bold = true })
        end,
      })
    end,
    opts = {
      flavour = "mocha",
      -- 灰色系の hl を白寄りに引き上げる（コメント・行番号・UI 薄字）
      custom_highlights = function(colors)
        return {
          -- コメント: overlay2 -> subtext0
          Comment = { fg = colors.subtext0, style = { "italic" } },
          -- 行番号: Mocha パレットの text で明るく統一
          -- Neovim 0.10+ では relativenumber 有効時に LineNrAbove/LineNrBelow が使われ
          -- LineNr 単体だと反映されないので 3 グループ同時に上書きする
          -- (実機では同梱 catppuccin.vim が後勝ちするため init の ColorScheme autocmd でも再上書き)
          LineNr = { fg = colors.text },
          LineNrAbove = { fg = colors.text },
          LineNrBelow = { fg = colors.text },
          -- カーソル行の行番号: Catppuccin 公式推奨の lavender で強調
          CursorLineNr = { fg = colors.lavender, style = { "bold" } },
          -- フロート枠
          FloatBorder = { fg = colors.overlay2 },
          -- ステータスライン (非アクティブ)
          StatusLineNC = { fg = colors.overlay2, bg = colors.mantle },
          -- WinBar (breadcrumb) 非アクティブ
          WinBarNC = { fg = colors.overlay2 },

          -- Neo-tree: 全体的に一段明るく
          NeoTreeNormal = { fg = colors.text },
          NeoTreeNormalNC = { fg = colors.text },
          NeoTreeFileName = { fg = colors.text },
          NeoTreeFileNameOpened = { fg = colors.subtext1, style = { "italic" } },
          NeoTreeDirectoryName = { fg = colors.sapphire },
          NeoTreeDirectoryIcon = { fg = colors.sapphire },
          NeoTreeRootName = { fg = colors.text, style = { "bold" } },
          NeoTreeIndentMarker = { fg = colors.overlay1 },
          NeoTreeExpander = { fg = colors.overlay1 },
          NeoTreeDimText = { fg = colors.subtext0 },
          NeoTreeMessage = { fg = colors.subtext0 },
          NeoTreeTitleBar = { fg = colors.text, bg = colors.surface0 },
          -- Git ステータスは色相維持。暗すぎた ignored だけ持ち上げる
          NeoTreeGitIgnored = { fg = colors.overlay0 },
          -- dotfile (.gitignore, .config など) を一段明るく
          NeoTreeDotfile = { fg = colors.subtext0 },
          NeoTreeHiddenByName = { fg = colors.subtext0 },
        }
      end,
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },
  -- 起動時のデフォルト設定に使用したい場合は下記を有効化する
  -- {
  --   "LazyVim/LazyVim",
  --   opts = {
  --     colorscheme = "catppuccin",
  --   },
  -- },
}
