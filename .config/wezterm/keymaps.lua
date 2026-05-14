local wezterm = require("wezterm")
local act = wezterm.action

-- フォントサイズを 0.5 単位で増減（IncreaseFontSize/DecreaseFontSize は 10% 単位なので別実装）
local function adjust_font_size(window, delta)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.font_size or window:effective_config().font_size
  overrides.font_size = current + delta
  window:set_config_overrides(overrides)
end

wezterm.on("font-size-increase-half", function(window, _)
  adjust_font_size(window, 0.5)
end)

wezterm.on("font-size-decrease-half", function(window, _)
  adjust_font_size(window, -0.5)
end)

-- Show which key table / leader state is active in the status area
wezterm.on("update-right-status", function(window, pane)
  local name = window:active_key_table()
  local label = name and string.upper(name) or (window:leader_is_active() and "LEADER" or nil)
  if label then
    window:set_right_status(wezterm.format({
      { Background = { Color = "#e06c75" } },
      { Foreground = { Color = "#282c34" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. label .. " " },
      "ResetAttributes",
    }))
  else
    window:set_right_status("")
  end
end)

return {
  keys = {
    -- コマンドパレット表示
    { key = "j", mods = "CTRL", action = act.ActivateCommandPalette },
    -- Tab操作: Alt+a でモード切替（もう一度 Alt+a or Escape で終了）
    {
      key = "a",
      mods = "ALT",
      action = act.ActivateKeyTable({ name = "tab_ops", one_shot = false }),
    },

    -- 画面フルスクリーン切り替え
    { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

    -- コピーモード
    { key = "c", mods = "LEADER", action = act.ActivateCopyMode },
    -- コピー
    { key = "c", mods = "CTRL", action = act.CopyTo("Clipboard") },
    -- 貼り付け
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

    -- Pane操作: Alt+q を押してから各キーを押す（Ctrl+q は Leader に予約済み）
    {
      key = "q",
      mods = "ALT",
      action = act.ActivateKeyTable({ name = "pane_ops", timeout_milliseconds = 2000 }),
    },

    -- フォントサイズ切替
    { key = ";", mods = "ALT", action = act.IncreaseFontSize },
    { key = ";", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
    { key = "-", mods = "ALT", action = act.DecreaseFontSize },
    { key = "-", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
    -- フォントサイズを 0.5 ずつ変更
    { key = ";", mods = "CTRL", action = act.EmitEvent("font-size-increase-half") },
    { key = "-", mods = "CTRL", action = act.EmitEvent("font-size-decrease-half") },
    -- フォントサイズのリセット
    { key = "0", mods = "ALT", action = act.ResetFontSize },
    { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },


    -- コマンドパレット
    { key = "p", mods = "CTRL|SHIFT|ALT", action = act.ActivateCommandPalette },
    -- 設定再読み込み
    { key = "r", mods = "CTRL|SHIFT|ALT", action = act.ReloadConfiguration },
  },
  -- キーテーブル
  -- https://wezfurlong.org/wezterm/config/key-tables.html
  key_tables = {
    -- Tab操作: Alt+a でトグル
    tab_ops = {
      -- Tab移動
      { key = "Tab", action = act.ActivateTabRelative(1) },
      { key = "Tab", mods = "SHIFT", action = act.ActivateTabRelative(-1) },
      -- Tab新規作成
      { key = "t", action = act({ SpawnTab = "CurrentPaneDomain" }) },
      -- Tabを閉じる
      { key = "w", action = act({ CloseCurrentTab = { confirm = true } }) },
      -- Tab入れ替え
      { key = "[", action = act({ MoveTabRelative = -1 }) },
      { key = "]", action = act({ MoveTabRelative = 1 }) },
      -- タブ切替 数字
      { key = "1", action = act.ActivateTab(0) },
      { key = "2", action = act.ActivateTab(1) },
      { key = "3", action = act.ActivateTab(2) },
      { key = "4", action = act.ActivateTab(3) },
      { key = "5", action = act.ActivateTab(4) },
      { key = "6", action = act.ActivateTab(5) },
      { key = "7", action = act.ActivateTab(6) },
      { key = "8", action = act.ActivateTab(7) },
      { key = "9", action = act.ActivateTab(-1) },
      -- モード終了
      { key = "a", mods = "ALT", action = "PopKeyTable" },
      { key = "Escape", action = "PopKeyTable" },
    },
    -- Pane操作: Alt+q を押してから各キーを押す
    pane_ops = {
      -- Pane作成
      { key = "d", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
      { key = "r", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
      -- Paneを閉じる
      { key = "x", action = act({ CloseCurrentPane = { confirm = true } }) },
      -- Pane移動
      { key = "h", action = act.ActivatePaneDirection("Left") },
      { key = "l", action = act.ActivatePaneDirection("Right") },
      { key = "k", action = act.ActivatePaneDirection("Up") },
      { key = "j", action = act.ActivatePaneDirection("Down") },
      -- Pane選択
      { key = "[", action = act.PaneSelect },
      -- 選択中のPaneのみ表示
      { key = "z", action = act.TogglePaneZoomState },
      -- Paneサイズ調整モード
      { key = "s", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
      -- Pane移動モード
      {
        key = "a",
        action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }),
      },
      -- モード終了
      { key = "Escape", action = "PopKeyTable" },
    },
    -- Paneサイズ調整
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

      -- Cancel the mode by pressing escape
      { key = "Enter", action = "PopKeyTable" },
    },
    activate_pane = {
      { key = "h", action = act.ActivatePaneDirection("Left") },
      { key = "l", action = act.ActivatePaneDirection("Right") },
      { key = "k", action = act.ActivatePaneDirection("Up") },
      { key = "j", action = act.ActivatePaneDirection("Down") },
    },
    -- copyモード leader + [
    copy_mode = {
      -- 移動
      { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
      { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
      { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
      { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
      -- 最初と最後に移動
      { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
      { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
      -- 左端に移動
      { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
      { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
      { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
      --
      { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
      -- 単語ごと移動
      { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
      { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
      -- ジャンプ機能 t f
      { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
      { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
      { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
      { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
      -- 一番下へ
      { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
      -- 一番上へ
      { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
      -- viweport
      { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
      { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
      { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
      -- スクロール
      { key = "b", mods = "ALT", action = act.CopyMode("PageUp") },
      { key = "f", mods = "ALT", action = act.CopyMode("PageDown") },
      { key = "d", mods = "ALT", action = act.CopyMode({ MoveByPage = 0.5 }) },
      { key = "u", mods = "ALT", action = act.CopyMode({ MoveByPage = -0.5 }) },
      -- 範囲選択モード
      { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
      { key = "v", mods = "ALT", action = act.CopyMode({ SetSelectionMode = "Block" }) },
      { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
      -- コピー
      { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },

      -- コピーモードを終了
      {
        key = "Enter",
        mods = "NONE",
        action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
      },
      { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
      { key = "c", mods = "ALT", action = act.CopyMode("Close") },
      { key = "q", mods = "NONE", action = act.CopyMode("Close") },
    },
  },
}
