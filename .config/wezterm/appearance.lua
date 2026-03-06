local wezterm = require("wezterm")
local module = {}

local appearance = {
  color_scheme = "Solarized Dark Higher Contrast",

  -- タイトルバーは使わず、最小化・最大化・閉じるをタブバー内に表示（透明のまま）
  window_decorations = "INTEGRATED_BUTTONS | RESIZE",
  integrated_title_buttons = { "Hide", "Maximize", "Close" }, -- 最小化, 最大化, 閉じる
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  -- Pane
  -- 非アクティブPaneを暗くして視認性を向上
  -- アクティブPaneは青みがかった背景、非アクティブは暗くする
  inactive_pane_hsb = {
    hue = 0.9, -- 色相を少しシフト（青みを抑える）
    saturation = 0.9,
    brightness = 1.0,
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
    -- 通常文字を明るく（暗い背景用）
    foreground = "#e2e2e2",
    -- 青みがかった背景色（アクティブPaneで青く見える）
    background = "#1a1a2e",
    -- タブバー背景を透過
    tab_bar = {
      background = "none",
      inactive_tab_edge = "none",
    },
    -- カーソルとコピーモード選択色（WezTermデフォルト）
    cursor_bg = "#80EBDF",
    cursor_fg = "#000000",
    cursor_border = "#80EBDF",
    selection_bg = "#ffdd00",
    selection_fg = "#000000",
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
