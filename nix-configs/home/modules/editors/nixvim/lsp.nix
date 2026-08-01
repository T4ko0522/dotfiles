{
  lsp = {
    inlayHints.enable = true;
    servers = {
      biome.enable = true;
      cssls.enable = true;
      docker_compose_language_service.enable = true;
      dockerls.enable = true;
      eslint.enable = true;
      gopls.enable = true;
      jsonls.enable = true;
      marksman.enable = true;
      nil_ls.enable = true;
      pyright.enable = true;
      ruff.enable = true;
      tailwindcss = {
        enable = true;
        config.filetypes = [
          "css"
          "html"
          "javascript"
          "javascriptreact"
          "typescript"
          "typescriptreact"
          "vue"
        ];
      };
      taplo.enable = true;
      vtsls.enable = true;
    };
  };

  plugins = {
    blink-cmp = {
      enable = true;
      setupLspCapabilities = true;
      settings = {
        cmdline.enabled = false;
        completion = {
          documentation.window.border = "rounded";
          menu.border = "rounded";
        };
        keymap = {
          preset = "default";
          "<CR>" = ["fallback"];
        };
        sources = {
          cmdline = [];
          providers.lazydev = {
            module = "lazydev.integrations.blink";
            name = "LazyDev";
            score_offset = 100;
          };
          per_filetype.lua = ["lsp" "path" "snippets" "buffer" "lazydev"];
        };
      };
    };

    friendly-snippets.enable = true;

    luasnip.enable = true;

    lazydev = {
      enable = true;
      settings.library = [
        {
          path = "\${3rd}/luv/library";
          words = ["vim%.uv"];
        }
        {
          path = "snacks.nvim";
          words = ["Snacks"];
        }
      ];
    };

    lsp.enable = true;
  };

  extraConfigLuaPost = ''
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          return string.format("%s (%s)", diagnostic.message, diagnostic.source or "Unknown")
        end,
      },
    })
  '';
}
