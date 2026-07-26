{
  config,
  lib,
  pkgs,
  ...
}: {
  extraPackages = with pkgs; [
    gofumpt
    gotools
    nixfmt
    prettier
    statix
    stylua
  ];

  extraFiles = {
    "ftdetect/mdc.lua".source = ../files/ftdetect/mdc.lua;
    "ftdetect/zsh.lua".source = ../files/ftdetect/zsh.lua;
    "spell/tech.utf-8.add".source = ../files/spell/tech.utf-8.add;
  };

  plugins = {
    emmet.enable = true;
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
    render-markdown.enable = true;
    rustaceanvim.enable = true;
    treesitter = {
      enable = true;
      grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
        bash
        c
        css
        dockerfile
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
        toml
        tsx
        typescript
        vim
        vimdoc
        yaml
        zsh
      ];
      highlight.enable = true;
      indent.enable = true;
    };
    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 3;
        min_window_height = 20;
        mode = "cursor";
        multiline_threshold = 1;
        trim_scope = "outer";
      };
    };
    ts-autotag.enable = true;
    ts-comments.enable = true;
    venv-selector.enable = true;
  };

  extraConfigLuaPost = lib.mkMerge [
    (lib.mkOrder 1100 ''
      local function markdown_fold_provider(buffer)
        local lines, folds, blocks, headings = vim.api.nvim_buf_get_lines(buffer, 0, -1, false), {}, {}, {}
        local in_code, code_start = false, nil
        local function trim_empty(last)
          while last > 0 and lines[last + 1] and lines[last + 1]:match("^%s*$") do last = last - 1 end
          return last
        end
        local function close_headings(level, last)
          while #headings > 0 and headings[#headings].level >= level do
            local heading = table.remove(headings)
            local finish = trim_empty(last - 1)
            if finish > heading.line then table.insert(folds, { startLine = heading.line, endLine = finish }) end
          end
        end
        for index, line in ipairs(lines) do
          local line_number = index - 1
          if line:match("^```") or line:match("^~~~") then
            if in_code then
              in_code = false
              if line_number > code_start then table.insert(folds, { startLine = code_start, endLine = line_number }) end
            else
              in_code, code_start = true, line_number
            end
          end
          if not in_code then
            if line:match("^:::details") or line:match("^:::message") then
              table.insert(blocks, line_number)
            elseif line:match("^:::$") and #blocks > 0 then
              table.insert(folds, { startLine = table.remove(blocks), endLine = line_number })
            end
            local hashes = line:match("^(#+)%s")
            if hashes then
              close_headings(#hashes, line_number)
              table.insert(headings, { line = line_number, level = #hashes })
            end
          end
        end
        local last = trim_empty(#lines - 1)
        for _, heading in ipairs(headings) do
          if last > heading.line then table.insert(folds, { startLine = heading.line, endLine = last }) end
        end
        return folds
      end
    '')
    (lib.mkOrder 1140 ''
      vim.g.bracey_auto_start_browser = 1
      vim.g.bracey_refresh_on_save = 1
      vim.g.bracey_server_allow_remote_connections = 0
      vim.g.user_emmet_leader_key = "<C-y>"
      vim.g.user_emmet_settings = {
        variables = { lang = "ja" },
        html = {
          indentation = "  ",
          snippets = {
            ["html:5"] = "<!DOCTYPE html>\n<html lang=\"''${lang}\">\n<head>\n\t<meta charset=\"''${charset}\">\n\t<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">\n\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n\t<title></title>\n</head>\n<body>\n\t''${child}|\n</body>\n</html>",
          },
        },
      }

      local spellfiles = vim.fn.globpath(vim.o.runtimepath, "spell/tech.utf-8.add", false, true)
      if #spellfiles > 0 then
        vim.opt.spellfile = { spellfiles[1], vim.fn.stdpath("data") .. "/spell/local.utf-8.add" }
      end
    '')
  ];
}
