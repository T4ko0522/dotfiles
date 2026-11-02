{
  config,
  pkgs,
  ...
}: {
  extraPackages = with pkgs; [
    alejandra
    biome
    cargo
    nixfmt
    prettierd
    prettier
    rustc
    shfmt
    stylua
  ];

  plugins = {
    conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          javascript.__raw = ''{ "biome", "prettierd", "prettier", stop_after_first = true }'';
          javascriptreact.__raw = ''{ "biome", "prettierd", "prettier", stop_after_first = true }'';
          typescript.__raw = ''{ "biome", "prettierd", "prettier", stop_after_first = true }'';
          typescriptreact.__raw = ''{ "biome", "prettierd", "prettier", stop_after_first = true }'';
          json.__raw = ''{ "biome", "prettierd", "prettier", stop_after_first = true }'';
          yaml.__raw = ''{ "prettierd", "prettier", stop_after_first = true }'';
          markdown.__raw = ''{ "prettierd", "prettier", stop_after_first = true }'';
          lua = ["stylua"];
          nix.__raw = ''{ "nix_fmt", "alejandra", stop_after_first = true }'';
          sh = ["shfmt"];
        };
        formatters.nix_fmt.command = "nixfmt";
        format_on_save = {
          lsp_format = "fallback";
          timeout_ms = 1000;
        };
      };
    };
    markdown-preview = {
      enable = true;
      settings = {
        auto_close = 0;
        browser = "";
        combine_preview = 0;
        combine_preview_auto_refresh = 1;
        filetypes = ["markdown"];
        open_to_the_world = 0;
        theme = "dark";
      };
    };
    treesitter = {
      enable = true;
      grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
        astro
        bash
        c
        css
        go
        html
        javascript
        json
        lua
        markdown
        markdown_inline
        nix
        python
        rust
        scss
        svelte
        toml
        tsx
        typescript
        vim
        vimdoc
        yaml
      ];
      highlight.enable = true;
      indent.enable = true;
    };
    treesitter-context.enable = true;
    ts-autotag.enable = true;
  };
}
