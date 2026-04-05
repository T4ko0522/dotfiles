return {
  "yetone/avante.nvim",
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    provider = "copilot",
  },
  keys = { "<leader>a", desc = "Avante" },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- Windows では make が失敗するため Build.ps1 を使う (avante_templates 生成に必須)
  -- Build.ps1 の prebuilt 取得は gh 認証未設定だと失敗しやすいため、Windows では source build を固定する
  build = vim.fn.has("win32") == 1
      and "powershell -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource true"
      or "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          -- use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
