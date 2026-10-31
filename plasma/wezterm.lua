local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0
config.default_prog = { 'fish', '--login' }
config.color_scheme = 'Tokyo Night'
config.colors = {
  foreground = '#c0caf5',
  background = '#1a1b26',
  cursor_bg = '#c0caf5',
  cursor_fg = '#1a1b26',
  selection_bg = '#33467c',
  selection_fg = '#c0caf5',
  ansi = { '#15161e', '#f7768e', '#9ece6a', '#e0af68', '#7aa2f7', '#bb9af7', '#7dcfff', '#a9b1d6' },
  brights = { '#414868', '#ff899d', '#b9f27c', '#ff9e64', '#8db0ff', '#c7a9ff', '#a4daff', '#c0caf5' },
}

config.window_background_opacity = 0.96
config.text_background_opacity = 1.0
config.window_padding = { left = 12, right = 12, top = 10, bottom = 10 }
config.window_decorations = 'RESIZE'
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = 'NeverPrompt'
config.scrollback_lines = 12000
config.keys = {
  { key = 'c', mods = 'CTRL|ALT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|ALT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.DisableDefaultAssignment },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.DisableDefaultAssignment },
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = false } },
}

return config
