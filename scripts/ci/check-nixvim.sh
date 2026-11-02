#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
nixvim_attr=".#nixosConfigurations.default.config.home-manager.users.t4ko.programs.nixvim.build"
nix_cache_options=(
  --option substituters "https://cache.nixos.org/"
  --option extra-substituters ""
)
cd "$repo_dir"

# Do not depend on personal binary caches: they can be unavailable outside the
# maintainer's environment. This only affects this local regression check.
nix build --no-link "${nix_cache_options[@]}" "$nixvim_attr.package"

nvim="$(nix eval --raw "${nix_cache_options[@]}" "$nixvim_attr.package")/bin/nvim"
init_file="$(nix eval --raw "${nix_cache_options[@]}" "$nixvim_attr.initFile")"
test_file="$(mktemp)"
trap 'rm -f "$test_file"' EXIT

cat >"$test_file" <<'LUA'
local function assert_true(condition, message)
  if not condition then error(message, 2) end
end

assert_true(vim.g.mapleader == ",", "generated init.lua was not loaded")

for _, module in ipairs({
  "blink.cmp",
  "conform",
  "barbar",
  "catppuccin",
  "colorizer",
  "copilot",
  "dropbar",
  "git-conflict",
  "glance",
  "ibl",
  "gitsigns",
  "lsp_signature",
  "markview",
  "neo-tree",
  "neotest",
  "nvim-autopairs",
  "nvim-lightbulb",
  "scrollbar",
  "spectre",
  "snacks",
  "toggleterm",
  "treesitter-context",
  "trouble",
  "ufo",
  "which-key",
  "yazi",
  "zen-mode",
}) do
  local ok, result = pcall(require, module)
  assert_true(ok and result ~= nil, "failed to load Lua module: " .. module)
end

for _, command in ipairs({
  "CoAuthoredBy",
  "ConformInfo",
  "CountCleanTextLength",
  "DiffviewOpen",
  "InsertDatetime",
  "Neotest",
  "PasteImage",
  "Copilot",
  "Markview",
  "Neotree",
  "ToggleTerm",
  "WakaTimeApiKey",
  "ZenMode",
  "WinResizerStartResize",
  "Yazi",
}) do
  assert_true(vim.fn.exists(":" .. command) == 2, "missing command: " .. command)
end

for _, lhs in ipairs({
  ";,",
  "ss",
  "zR",
  "K",
  "<C-j>",
  "]h",
  ",cf",
  ",gg",
  ",gd",
  ",hs",
  ",tt",
  ",uC",
  ",wr",
}) do
  assert_true(next(vim.fn.maparg(lhs, "n", false, true)) ~= nil, "missing normal-mode keymap: " .. lhs)
end

for _, lhs in ipairs({ "<C-l>", "<C-g>", "<C-j>", "<C-]>" }) do
  assert_true(next(vim.fn.maparg(lhs, "i", false, true)) ~= nil, "missing insert-mode keymap: " .. lhs)
end

assert_true(require("blink.cmp.config").cmdline.enabled == false, "Blink cmdline completion must be disabled")
assert_true(vim.g.colors_name == "catppuccin-mocha", "Catppuccin must be active")
assert_true(require("catppuccin").options.transparent_background, "Catppuccin background must be transparent")
assert_true(vim.o.relativenumber and vim.o.shiftwidth == 2, "reference editor options must be loaded")
assert_true(vim.fn.exists(":SupermavenStart") == 0, "Supermaven must be replaced by Copilot")

local formatters = require("conform").formatters_by_ft
assert_true(formatters.typescript[1] == "biome" and formatters.typescript.stop_after_first,
  "TypeScript must prefer Biome")
assert_true(formatters.nix[1] == "nix_fmt" and formatters.nix.stop_after_first,
  "Nix must prefer nixfmt")
for _, server in ipairs({ "vtsls", "biome", "tailwindcss", "cssls", "jsonls", "yamlls", "lua_ls",
  "nixd", "rust_analyzer", "svelte", "ty", "ruff", "astro", "gopls" }) do
  assert_true(vim.lsp.is_enabled(server), "LSP must be enabled: " .. server)
end

print("Nixvim headless regression checks passed")
LUA

"$nvim" --headless -u "$init_file" "+luafile $test_file" \
  "+if v:errmsg != '' | cquit | endif" \
  "+qa!"
