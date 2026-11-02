{localPackages}: {
  plugins.copilot-lua = {
    enable = true;
    package = localPackages.copilotLua;
    settings = {
      suggestion = {
        auto_trigger = true;
        keymap = {
          accept = false;
          accept_word = false;
          accept_line = false;
          next = false;
          prev = false;
          dismiss = false;
        };
      };
      panel.keymap.open = false;
    };
  };

  extraConfigLuaPost = ''
    local suggestion = require("copilot.suggestion")
    local function accept_suggestion()
      if suggestion.is_visible() then
        suggestion.accept()
      else
        vim.notify("No Copilot suggestion", vim.log.levels.WARN)
      end
    end

    local map = vim.keymap.set
    map("i", "<C-l>", accept_suggestion, { silent = true, desc = "Accept Copilot suggestion" })
    map("i", "<C-g>", accept_suggestion, { silent = true, desc = "Accept Copilot suggestion" })
    map("i", "<C-j>", suggestion.accept_word, { silent = true, desc = "Accept Copilot word" })
    map("i", "<C-]>", suggestion.dismiss, { silent = true, desc = "Clear Copilot suggestion" })
  '';
}
