local wezterm = require("wezterm")
local module = {}

local appearance = {
  color_scheme = "Catppuccin Mocha",

  -- タイトルバーとウィンドウボタン（最小化・最大化・閉じる）を非表示
  window_decorations = "RESIZE",
  integrated_title_buttons = {},
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  -- Pane
  -- 非アクティブPaneを暗くして視認性を向上
  inactive_pane_hsb = {
    hue = 1.0,
    saturation = 0.85,
    brightness = 0.85,
  },

  -- Tab
  show_tabs_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = false,
  show_new_tab_button_in_tab_bar = true,
  show_close_tab_button_in_tabs = true, -- Can only be used in nightly
  tab_max_width = 30,
  use_fancy_tab_bar = true,
  -- タブバー（上部）を透過
  window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  },
  -- Hide borders between tabs
  colors = {
    -- Catppuccin Mocha ベースの紫系配色
    foreground = "#cdd6f4", -- Text
    background = "#1e1e2e", -- Base（深い紫みの黒）
    -- タブバー背景を透過
    tab_bar = {
      background = "none",
      inactive_tab_edge = "none",
    },
    cursor_bg = "#f5c2e7", -- Pink
    cursor_fg = "#1e1e2e",
    cursor_border = "#f5c2e7",
    selection_bg = "#585b70", -- Surface2
    selection_fg = "#cdd6f4",
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
