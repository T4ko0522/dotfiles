return {
  -- Disable markdownlint (use rumdl instead via CLI)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  -- 全LSPサーバーをNixで管理するためMasonの自動インストールを無効化
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          format = function(diagnostic)
            return string.format("%s (%s)", diagnostic.message, diagnostic.source or "Unknown")
          end,
        },
      },
      servers = {
        -- Nix管理のLSPサーバー (mason = false)
        marksman = { mason = false },
        nil_ls = { mason = false },
        tailwindcss = { mason = false },
        gopls = { mason = false },
        pyright = { mason = false },
        ruff = { mason = false },
        biome = { mason = false },
        vtsls = { mason = false },
        jsonls = { mason = false },
        dockerls = { mason = false },
        docker_compose_language_service = { mason = false },
        eslint = { mason = false },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "rounded",
        },
        documentation = {
          window = {
            border = "rounded",
          },
        },
      },
      keymap = {
        -- preset = "none",
        ["<CR>"] = {}, -- Do not use enter to confirm completion
      },
      sources = {
        default = {
          cmdline = {}, -- Disable cmdline completions (conflicts with Snacks picker)
        },
      },
    },
  },
}
