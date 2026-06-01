local module = {}

-- ステータス定義
module.STATUS = {
  running = { icon = "●", color = "#57A143" },
  waiting = { icon = "◐", color = "#ffd700" },
  idle    = { icon = "○", color = "#a0a9cb" },
}

-- Claudeプロセスかどうか判定
function module.is_claude(process_name, pane_title)
  return process_name == "claude"
    or (pane_title and (pane_title:find("^✳") or pane_title:lower():find("claude")))
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
