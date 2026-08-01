{
  plugins = {
    diffview = {
      enable = true;
      settings = {
        enhanced_diff_hl = true;
        file_panel = {
          listing_style = "tree";
          win_config = {
            position = "left";
            width = 35;
          };
        };
        view.merge_tool = {
          disable_diagnostics = true;
          layout = "diff3_mixed";
        };
      };
    };
    gitsigns = {
      enable = true;
    };
  };

  extraConfigLuaPost = ''
    local function gitsigns_map(mode, lhs, method, desc)
      vim.keymap.set(mode, lhs, function()
        local gitsigns = require("gitsigns")
        if mode == "v" then
          gitsigns[method]({ vim.fn.line("."), vim.fn.line("v") })
        else
          gitsigns[method]()
        end
      end, { silent = true, desc = desc })
    end

    vim.keymap.set("n", "]h", function()
      require("gitsigns").nav_hunk("next")
    end, { silent = true, desc = "Next hunk" })
    vim.keymap.set("n", "[h", function()
      require("gitsigns").nav_hunk("prev")
    end, { silent = true, desc = "Previous hunk" })
    gitsigns_map("n", "<leader>hs", "stage_hunk", "Stage hunk")
    gitsigns_map("n", "<leader>hr", "reset_hunk", "Reset hunk")
    gitsigns_map("v", "<leader>hs", "stage_hunk", "Stage hunk")
    gitsigns_map("v", "<leader>hr", "reset_hunk", "Reset hunk")
    gitsigns_map("n", "<leader>hS", "stage_buffer", "Stage buffer")
    gitsigns_map("n", "<leader>hR", "reset_buffer", "Reset buffer")
    gitsigns_map("n", "<leader>hp", "preview_hunk", "Preview hunk")
    vim.keymap.set("n", "<leader>hb", function()
      require("gitsigns").blame_line({ full = true })
    end, { silent = true, desc = "Blame line" })
  '';
}
