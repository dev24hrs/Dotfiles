--  refer to https://wezterm.org/config/files.html

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- --- 字体设置 ---
config.font = wezterm.font_with_fallback({
	{ family = "RecMonoCasual Nerd Font Mono", weight = "Regular" },
	{ family = "Source Han Sans SC VF", weight = "Regular" }, -- 思源黑体中文
})
config.font_size = 19
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.line_height = 1.0

-- --- 界面显示 ---
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.initial_cols = 155
config.initial_rows = 50
config.default_cursor_style = "SteadyBar"
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false

-- --- 颜色与特效 ---
config.color_scheme = "Gruvbox Dark (Gogh)"
config.macos_window_background_blur = 25
-- 若需要开启透明度，取消下面注释：
config.window_background_opacity = 0.96
config.text_background_opacity = 0.96
config.term = "xterm-256color"

config.window_padding = {
	left = "1cell",
	right = "1cell",
	top = "0.0cell",
	bottom = "0.0cell",
}
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
local act = wezterm.action
config.keys = {
	{ key = "a", mods = "LEADER", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "m", mods = "LEADER", action = act.ToggleFullScreen },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}
for i = 1, 5 do
	-- CMD + number to activate that window
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CMD",
		action = act.ActivateWindow(i - 1),
	})
end
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

return config
