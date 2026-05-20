return {
  {
    "catppuccin/nvim",
    lazy = false, -- colorscheme として最優先で読み込む
    priority = 1000,
    name = "catppuccin",
    -- 透過背景: catppuccin の :colorscheme より前に autocmd を仕込んでおく必要があるため
    -- init (= setup より前) で登録する。VeryLazy の autocmds.lua では遅すぎて
    -- ColorScheme イベントを取り逃すため、ここに置く。
    init = function()
      local groups = {
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
        group = vim.api.nvim_create_augroup("transparent_bg", { clear = true }),
        callback = function()
          for _, g in ipairs(groups) do
            vim.api.nvim_set_hl(0, g, { bg = "NONE", ctermbg = "NONE" })
          end
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
          -- 行番号: surface1 (暗) -> overlay2
          LineNr = { fg = colors.overlay2 },
          -- カーソル行の行番号: lavender -> text
          CursorLineNr = { fg = colors.text, style = { "bold" } },
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
