{
  globals = {
    mapleader = ",";
    maplocalleader = "\\";
    clipboard = "osc52";
    loaded_ruby_provider = 0;
    loaded_perl_provider = 0;
  };

  env = {
    LANG = "ja_JP.UTF-8";
    LC_MESSAGES = "ja_JP.UTF-8";
  };

  opts = {
    number = true;
    relativenumber = true;
    signcolumn = "yes";
    termguicolors = true;
    mouse = "a";
    clipboard = "unnamedplus";
    updatetime = 200;
    timeoutlen = 300;
    undofile = true;
    wrap = false;
    scrolloff = 8;
    ignorecase = true;
    smartcase = true;
    splitright = true;
    splitbelow = true;
    tabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    encoding = "utf-8";
    fileencoding = "utf-8";
    fileencodings = "utf-8,sjis,euc-jp,iso-2022-jp";
    list = true;
    listchars = "tab:»-,trail:-,extends:»,precedes:«,nbsp:%";
    helplang = ["ja" "en"];
    jumpoptions = "stack";
    switchbuf = "useopen,uselast";
    foldcolumn = "1";
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;
  };

  extraConfigLuaPost = ''
    vim.cmd.language("ja_JP.utf8")
    vim.cmd("cabbrev H belowright vertical help")
  '';
}
