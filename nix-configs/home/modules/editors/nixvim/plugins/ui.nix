{
  colorschemes.catppuccin = {
    enable = true;
    settings.transparent_background = true;
  };

  plugins = {
    barbar = {
      enable = true;
      settings = {
        animation = false;
        auto_hide = 1;
        tabpages = true;
        clickable = true;
        focus_on_close = "left";
        icons = {
          button = "󰅖";
          separator = {
            left = "▎";
            right = "";
          };
          separator_at_end = false;
          filetype.enabled = true;
        };
        sidebar_filetypes.neo-tree = true;
      };
    };
    colorizer = {
      enable = true;
      settings = {
        filetypes = ["*" "!markdown"];
        user_commands = true;
        options = {
          parsers = {
            css = true;
            tailwind = {
              enable = true;
              lsp = true;
              update_names = true;
            };
          };
          display.mode = "background";
        };
      };
    };
    dropbar.enable = true;
    indent-blankline = {
      enable = true;
      settings = {
        scope = {
          enabled = true;
          show_start = true;
          show_end = true;
        };
        exclude.filetypes = ["help" "neo-tree" "toggleterm" "lazy"];
      };
    };
    lualine = {
      enable = true;
      settings.sections.lualine_x = [
        {
          __raw = ''
            function()
              local formatters = require("conform").list_formatters(0)
              for _, formatter in ipairs(formatters) do
                if formatter.available then return "󰛖 " .. formatter.name end
              end
              return ""
            end
          '';
        }
        "encoding"
        "fileformat"
        "filetype"
      ];
    };
    markview = {
      enable = true;
      settings.preview.enable = false;
    };
    nvim-lightbulb = {
      enable = true;
      settings.autocmd.enabled = true;
    };
    web-devicons.enable = true;
    zen-mode.enable = true;
  };

  extraConfigLuaPost = ''
    require("scrollbar").setup()
  '';
}
