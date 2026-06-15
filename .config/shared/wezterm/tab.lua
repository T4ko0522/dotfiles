local wezterm = require("wezterm")
local claude_status = require("modules.claude_status")
local module = {}

-- =============================================================================
-- 定数
-- =============================================================================

-- Icons
local ICONS = {
  docker = wezterm.nerdfonts.md_docker,
  neovim = wezterm.nerdfonts.linux_neovim,
  ssh = wezterm.nerdfonts.md_lan,
  fallback = wezterm.nerdfonts.dev_terminal,
  zoom = wezterm.nerdfonts.md_magnify,
}

-- Icon colors (Catppuccin Mocha 系の紫テーマに合わせて調整)
local ICON_COLORS = {
  docker = "#89b4fa", -- Blue
  neovim = "#a6e3a1", -- Green
  ssh = "#f38ba8",    -- Red/Pink
}

-- Tab colors
local TAB_COLORS = {
  foreground_inactive = "#a6adc8", -- Subtext0
  background_inactive = "#1e1e2e", -- Base
  foreground_active = "#1e1e2e",   -- Base（アクティブタブ文字）
  background_active = "#cba6f7",   -- Mauve（ラベンダー）
  background_ssh_active = "#f38ba8",
  foreground_ssh_active = "#1e1e2e",
}

-- Tab decorations
local DECORATIONS = {
  left_circle = wezterm.nerdfonts.ple_left_half_circle_thick,
  right_circle = wezterm.nerdfonts.ple_right_half_circle_thick,
}

-- =============================================================================
-- ヘルパー関数
-- =============================================================================

local function basename(path)
  return string.gsub(path or "", "(.*[/\\])(.*)", "%2")
end

local function is_ssh_process(process_name, cmdline, user_vars)
  if user_vars.ssh_host and user_vars.ssh_host ~= "" then
    return true, user_vars.ssh_host
  end
  if process_name:find("ssh") or (cmdline and cmdline:find("ssh")) then
    local host = cmdline and cmdline:match("ssh%s+([%w_%-%.]+)")
    return true, host
  end
  return false, nil
end


local function extract_project_name(cwd)
  if not cwd then
    return "-"
  end

  local home = os.getenv("HOME")
  if home and cwd:find("^" .. home) then
    cwd = cwd:gsub("^" .. home, "~")
  end

  -- GitHubプロジェクト名
  local _, project = cwd:match(".*/src/github.com/([^/]+)/([^/]+)")
  if project then
    return project
  end

  -- 最後のディレクトリ名
  cwd = cwd:gsub("/$", "")
  return cwd:match("([^/]+)$") or cwd
end

local function get_icon_and_color(process_name, pane_title, cmdline, cwd, is_ssh, is_active)
  if is_ssh then
    local color = is_active and "#ffffff" or ICON_COLORS.ssh
    return ICONS.ssh, color
  end

  if pane_title == "nvim" or process_name == "nvim" then
    return ICONS.neovim, ICON_COLORS.neovim
  end

  if process_name == "docker" or (pane_title and pane_title:find("docker")) then
    return ICONS.docker, ICON_COLORS.docker
  end

  return ICONS.fallback, TAB_COLORS.foreground_inactive
end

local function get_tab_colors(is_active, is_ssh)
  if is_active and is_ssh then
    return TAB_COLORS.background_ssh_active, TAB_COLORS.foreground_ssh_active
  elseif is_active then
    return TAB_COLORS.background_active, TAB_COLORS.foreground_active
  end
  return TAB_COLORS.background_inactive, TAB_COLORS.foreground_inactive
end

local function has_zoomed_pane(panes)
  for _, pane_info in ipairs(panes) do
    if pane_info.is_zoomed then
      return true
    end
  end
  return false
end

-- =============================================================================
-- メイン処理
-- =============================================================================

function module.apply_to_config(config)
  local title_cache = {}
  local ssh_host_cache = {}

  -- タイトルキャッシュの更新
  wezterm.on("update-status", function(_, pane)
    local pane_id = pane:pane_id()
    local user_vars = pane.user_vars or {}

    -- SSH中以外はタイトルキャッシュを更新
    if not (user_vars.ssh_host and user_vars.ssh_host ~= "") then
      local cwd_url = pane:get_current_working_dir()
      local cwd = cwd_url and cwd_url.file_path
      title_cache[pane_id] = extract_project_name(cwd)
    end
  end)

  -- タブタイトルのフォーマット
  wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    local pane = tab.active_pane
    local pane_id = pane.pane_id
    local process_name = basename(pane.foreground_process_name)
    local pane_title = pane.title or ""
    local cmdline = pane.foreground_process_name or ""
    local user_vars = pane.user_vars or {}
    local cached_cwd = title_cache[pane_id] or ""

    -- SSH判定
    local is_ssh, ssh_host = is_ssh_process(process_name, cmdline, user_vars)
    if is_ssh and ssh_host then
      ssh_host_cache[pane_id] = ssh_host
    elseif not is_ssh then
      ssh_host_cache[pane_id] = nil
    end

    -- タブの色（edge を透過でタブバー上部が透ける）
    local background, foreground = get_tab_colors(tab.is_active, is_ssh)
    local edge_background = "none"
    local edge_foreground = background

    -- タイトルテキスト
    local title_text
    if is_ssh then
      title_text = ssh_host_cache[pane_id] or "ssh"
    else
      title_text = title_cache[pane_id] or "-"
    end

    -- アイコン
    local icon, icon_color = get_icon_and_color(process_name, pane_title, cmdline, cached_cwd, is_ssh, tab.is_active)

    -- ズームインジケーター
    local zoom_indicator = has_zoomed_pane(tab.panes) and (ICONS.zoom .. " ") or ""

    -- -- 半円
    local left_circle = DECORATIONS.left_circle
    local right_circle = DECORATIONS.right_circle

    -- タイトルの整形
    local title = " " .. wezterm.truncate_right(title_text, max_width) .. " "

    -- Claude ステータス（タブ内の全ペインを走査してセッション分を列挙）
    local claude_statuses = {}
    for _, pane_info in ipairs(tab.panes) do
      local p_name = basename(pane_info.foreground_process_name or "")
      local p_title = pane_info.title or ""
      if claude_status.is_claude(p_name, p_title) then
        local status = claude_status.get_status(p_title)
        local s = claude_status.STATUS[status]
        if s then
          table.insert(claude_statuses, s)
        end
      end
    end

    local tab_elements = {
      { Background = { Color = edge_background } },
      { Text = " " },
      { Foreground = { Color = edge_foreground } },
      { Text = left_circle },
      { Background = { Color = background } },
      { Foreground = { Color = icon_color } },
      { Text = icon },
    }

    -- Claude ステータスをアイコン直後に挿入（セッション数だけアイコンを並べる）
    if #claude_statuses > 0 then
      for i, s in ipairs(claude_statuses) do
        table.insert(tab_elements, { Foreground = { Color = s.color } })
        local prefix = (i == 1) and "   " or " "
        table.insert(tab_elements, { Text = prefix .. s.icon })
      end
      table.insert(tab_elements, { Text = " " })
    end

    table.insert(tab_elements, { Background = { Color = background } })
    table.insert(tab_elements, { Foreground = { Color = foreground } })
    table.insert(tab_elements, { Text = zoom_indicator })
    table.insert(tab_elements, { Attribute = { Intensity = "Bold" } })
    table.insert(tab_elements, { Text = title })

    table.insert(tab_elements, { Attribute = { Intensity = "Normal" } })
    table.insert(tab_elements, { Background = { Color = edge_background } })
    table.insert(tab_elements, { Foreground = { Color = edge_foreground } })
    table.insert(tab_elements, { Text = right_circle })

    return tab_elements
  end)
end

return module
