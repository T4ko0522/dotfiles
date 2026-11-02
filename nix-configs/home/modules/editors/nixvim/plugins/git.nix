{
  plugins = {
    diffview.enable = true;
    git-conflict = {
      enable = true;
      settings.default_mappings = false;
    };
    lazygit.enable = true;
    gitsigns = {
      enable = true;
      settings.signs = {
        add.text = "+";
        change.text = "~";
        delete.text = "_";
        topdelete.text = "‾";
        changedelete.text = "~";
      };
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
