{
  lsp.servers = {
    vtsls = {
      enable = true;
      packageFallback = true;
      config = {
        root_markers = [
          "pnpm-workspace.yaml"
          "package.json"
          "tsconfig.json"
          "jsconfig.json"
          ".git"
        ];
        settings.typescript.locale = "ja";
      };
    };
    biome = {
      enable = true;
      packageFallback = true;
      config.root_markers = [
        "biome.json"
        "biome.jsonc"
        "package.json"
        "pnpm-workspace.yaml"
        ".git"
      ];
    };
    tailwindcss.enable = true;
    cssls.enable = true;
    jsonls.enable = true;
    yamlls.enable = true;
    lua_ls.enable = true;
    nixd.enable = true;
    rust_analyzer.enable = true;
    svelte.enable = true;
    ty.enable = true;
    ruff.enable = true;
    astro.enable = true;
    gopls.enable = true;
  };

  diagnostic.settings = {
    virtual_text = true;
    float = {
      border = "rounded";
      source = true;
    };
  };

  plugins = {
    blink-cmp = {
      enable = true;
      setupLspCapabilities = true;
      settings = {
        cmdline.enabled = false;
        keymap = {
          preset = "default";
          "<CR>" = ["fallback"];
        };
        completion.list.selection = {
          preselect = true;
          auto_insert = false;
        };
        sources = {
          cmdline = [];
          default = ["lsp" "path" "buffer"];
        };
      };
    };
    lsp.enable = true;
  };
}
