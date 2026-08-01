{
  plugins.neotest = {
    enable = true;
    adapters = {
      go.enable = true;
      plenary.enable = true;
      python.enable = true;
      rust.enable = true;
      vitest.enable = true;
    };
  };

  extraConfigLuaPost = ''
    local neotest = require("neotest")
    local map = vim.keymap.set
    map("n", "<leader>tt", function() neotest.run.run() end, { desc = "Run nearest test" })
    map("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "Run test file" })
    map("n", "<leader>ts", neotest.summary.toggle, { desc = "Toggle test summary" })
    map("n", "<leader>to", neotest.output.open, { desc = "Open test output" })
  '';
}
