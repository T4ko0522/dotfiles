local module = {}

-- ステータス定義
-- アイコンは Claude Code 本物のロゴ ✳ (U+2733) に統一し、色で状態を区別する。
--   running = Claude ブランドのオレンジ / waiting = Yellow / idle = 控えめな Overlay0
module.STATUS = {
  running = { icon = "✳", color = "#d97757" }, -- Claude Orange（生成中）
  waiting = { icon = "✳", color = "#f9e2af" }, -- Yellow（入力待ち）
  idle = { icon = "✳", color = "#6c7086" }, -- Overlay0（アイドル）
}

-- Claudeプロセスかどうか判定
function module.is_claude(process_name, pane_title)
  return process_name == "claude" or (pane_title and (pane_title:find("^✳") or pane_title:lower():find("claude")))
end

-- ペインタイトルからステータスを判定
function module.get_status(pane_title)
  if not pane_title or pane_title == "" then
    return "idle"
  end
  -- 点字スピナー (U+2800-U+28FF)
  if pane_title:find("\xe2\xa0") then
    return "running"
  end
  -- ✳ (U+2733)
  if pane_title:find("\xe2\x9c\xb3") then
    return "waiting"
  end
  return "idle"
end

return module
