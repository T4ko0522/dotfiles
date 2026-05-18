---@type Wezterm
local wezterm = require("wezterm")

-- ここに設定内容を記述していく
local config = wezterm.config_builder()

-- 設定ファイルの変更を自動で読み込む
config.automatically_reload_config = true
config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" }
config.default_cwd = wezterm.home_dir .. "\\Project"

-- font
config.font_size = 13.0
config.font = wezterm.font_with_fallback({
  "PlemolJP Console NF",
  "Cascadia Mono",
})

-- GPU レンダラー（OpenGLコンテキスト喪失対策）
config.front_end = "OpenGL"

-- 背景の透過度
config.window_background_opacity = 0.7

-- タスク完了時の通知
config.audible_bell = "SystemBeep"
config.visual_bell = {
  fade_in_duration_ms = 0,
  fade_out_duration_ms = 0,
}

local keymaps = require("keymaps")
if type(keymaps.apply_to_config) == "function" then
  keymaps.apply_to_config(config)
else
  config.disable_default_key_bindings = true
  config.keys = keymaps.keys or {}
  config.key_tables = keymaps.key_tables or {}
  config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }
end
require("workspace").apply_to_config(config)
require("appearance").apply_to_config(config)
require("tab").apply_to_config(config)
require("statusbar").apply_to_config(config)

-- オプショナルモジュール（keymapsの後に読み込む）
require("modules.opacity").apply_to_config(config)
require("modules.wsl").apply_to_config(config)

return config
