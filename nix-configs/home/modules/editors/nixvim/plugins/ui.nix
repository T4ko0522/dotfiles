{lib, ...}: {
  plugins = {
    bufferline.enable = true;
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
    lualine = {
      enable = true;
      settings.options.theme = "dracula-nvim";
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
    web-devicons.enable = true;
  };

  extraConfigLuaPost = lib.mkMerge [
    (lib.mkOrder 1110 ''
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
    '')
    (lib.mkOrder 1130 ''
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
    '')
  ];
}
