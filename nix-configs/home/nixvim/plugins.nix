{
  config,
  pkgs,
  ...
}: let
  vimdocJa = pkgs.vimUtils.buildVimPlugin {
    pname = "vimdoc-ja";
    version = "2026-07-15";
    src = pkgs.fetchFromGitHub {
      owner = "vim-jp";
      repo = "vimdoc-ja";
      rev = "c8c3b339302b4e88be2859b3ba99a4f0a3a2f8bd";
      hash = "sha256-362QsKxCbqXrOru3p+ReoqtfwTLSSblNGzzxTE2DWoI=";
    };
  };

  winresizer = pkgs.vimUtils.buildVimPlugin {
    pname = "winresizer";
    version = "2026-07-15";
    src = pkgs.fetchFromGitHub {
      owner = "simeji";
      repo = "winresizer";
      rev = "299076f7f79e2e2f7706b2dfacbb3c074ce53257";
      hash = "sha256-rTTe6hFgEz9CFPJFDUjoD3SQr97V5E5Lg6J4c8mU+6s=";
    };
  };
in {
  extraPackages = with pkgs; [
    gofumpt
    gotools
    markdownlint-cli2
    nixfmt
    prettier
    statix
    stylua
  ];

  extraPlugins = with pkgs.vimPlugins; [
    bracey-vim
    dracula-nvim
    incline-nvim
    nvim-ufo
    promise-async
    vimdocJa
    winresizer
  ];

  extraFiles = {
    "ftdetect/mdc.lua".source = ../../../.config/shared/nvim/ftdetect/mdc.lua;
    "ftdetect/zsh.lua".source = ../../../.config/shared/nvim/ftdetect/zsh.lua;
    "spell/tech.utf-8.add".source = ../../../.config/shared/nvim/spell/tech.utf-8.add;
  };

  plugins = {
    bufferline.enable = true;
    claudecode = {
      enable = true;
      settings = {
        diff_opts = {
          layout = "vertical";
          open_in_new_tab = true;
        };
        terminal.provider = "snacks";
      };
    };
    compiler.enable = true;
    diffview.enable = true;
    emmet.enable = true;
    flash.enable = true;
    gitsigns.enable = true;
    grug-far.enable = true;
    hlchunk = {
      enable = true;
      settings.chunk = {
        chars = {
          horizontal_line = "─";
          left_bottom = "╰";
          left_top = "╭";
          right_arrow = ">";
          vertical_line = "│";
        };
        enable = true;
        style = "#806d9c";
      };
    };
    img-clip = {
      enable = true;
      settings.default = {
        dir_path = "assets";
        extension = "png";
        prompt_for_file_name = true;
        relative_to_current_file = true;
        show_dir_path_in_prompt = false;
        use_absolute_path = false;
      };
    };
    inc-rename.enable = true;
    lualine = {
      enable = true;
      settings.options.theme = "dracula-nvim";
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
    mini = {
      enable = true;
      modules = {
        ai = {};
        hipatterns = {};
        pairs = {};
        surround = {
          mappings = {
            add = "gsa";
            delete = "gsd";
            find = "gsf";
            find_left = "gsF";
            highlight = "gsh";
            replace = "gsr";
            update_n_lines = "gsn";
          };
        };
      };
    };
    modicator = {
      enable = true;
      settings = {
        highlights.defaults.bold = true;
        integration.lualine.enabled = false;
        show_warnings = false;
      };
    };
    noice = {
      enable = true;
      settings = {
        lsp = {
          hover = {
            enabled = true;
            silent = true;
          };
          signature.enabled = true;
        };
        presets = {
          bottom_search = true;
          command_palette = true;
          inc_rename = true;
          long_message_to_split = true;
          lsp_doc_border = true;
        };
        routes = [
          {
            filter = {
              event = "msg_show";
              find = "written";
              kind = "";
            };
            opts.skip = true;
          }
          {
            filter = {
              event = "msg_show";
              kind = "search_count";
            };
            opts.skip = true;
          }
        ];
      };
    };
    notify = {
      enable = true;
      settings = {
        background_colour = "#1e1e2e";
        render = "compact";
        stages = "fade";
        timeout = 3000;
      };
    };
    persistence.enable = true;
    rainbow-delimiters.enable = true;
    render-markdown.enable = true;
    rustaceanvim.enable = true;
    smear-cursor = {
      enable = true;
      settings = {
        distance_stop_animating = 0.5;
        hide_target_hack = false;
        stiffness = 0.8;
        trailing_exponent = 2;
        trailing_stiffness = 0.5;
      };
    };
    snacks = {
      enable = true;
      settings = {
        image = {
          doc = {
            enabled = true;
            inline = true;
            max_height = 40;
            max_width = 80;
          };
          enabled = true;
        };
        scroll.enabled = false;
      };
    };
    todo-comments.enable = true;
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
    trouble.enable = true;
    ts-autotag.enable = true;
    ts-comments.enable = true;
    venv-selector.enable = true;
    web-devicons.enable = true;
    which-key.enable = true;
    yazi = {
      enable = true;
      settings = {
        keymaps.show_help = "<f1>";
        open_for_directories = false;
      };
    };
  };

  extraConfigLuaPost = ''
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

    local dracula = require("dracula")
    dracula.setup({
      italic_comment = true,
      overrides = function(colors)
        return {
          CursorLineNr = { fg = colors.purple, bold = true },
          LineNr = { fg = colors.white },
          LineNrAbove = { fg = colors.white },
          LineNrBelow = { fg = colors.white },
        }
      end,
      transparent_bg = false,
    })
    vim.cmd.colorscheme("dracula")

    vim.o.cursorline = true
    vim.o.number = true
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    require("ufo").setup({
      fold_virt_text_handler = function(virtual_text, start_line, end_line, width, truncate)
        local suffix = (" 󰁂 %d "):format(end_line - start_line)
        local target_width, current_width = width - vim.fn.strdisplaywidth(suffix), 0
        local result = {}
        for _, chunk in ipairs(virtual_text) do
          local text, highlight = chunk[1], chunk[2]
          local text_width = vim.fn.strdisplaywidth(text)
          if target_width > current_width + text_width then
            table.insert(result, chunk)
          else
            text = truncate(text, target_width - current_width)
            table.insert(result, { text, highlight })
            suffix = suffix .. string.rep(" ", math.max(0, target_width - current_width - vim.fn.strdisplaywidth(text)))
            break
          end
          current_width = current_width + text_width
        end
        table.insert(result, { suffix, "MoreMsg" })
        return result
      end,
      provider_selector = function(buffer, filetype)
        if filetype == "markdown" then return markdown_fold_provider end
        return { "treesitter", "indent" }
      end,
    })

    require("incline").setup({
      hide = { cursorline = true },
      highlight = {
        groups = {
          InclineNormal = { guibg = "#BD93F9", guifg = "#282A36" },
          InclineNormalNC = { guibg = "#44475A", guifg = "#6272A4" },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
    })

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
  '';
}
