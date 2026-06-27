local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- On Windows, default into the Fedora WSL instance
if wezterm.target_triple:find('windows') then
  config.default_domain = 'WSL:FedoraLinux-44'
end

-- Font — change to whichever Nerd Font you installed
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 12.0

-- Catppuccin Mocha (matches nvim theme)
config.color_scheme = 'Catppuccin Mocha'

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_background_opacity = 0.95  -- 0.0 fully transparent, 1.0 solid
config.window_decorations = 'TITLE | RESIZE'
config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.window_close_confirmation = 'NeverPrompt'
config.check_for_updates = false

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- Cursor
config.default_cursor_style = 'BlinkingBar'

-- Clickable URLs in brackets, parens, angle brackets etc.
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, { regex = '\\((\\w+://\\S+)\\)',   format = '$1', highlight = 1 })
table.insert(config.hyperlink_rules, { regex = '\\[(\\w+://\\S+)\\]',   format = '$1', highlight = 1 })
table.insert(config.hyperlink_rules, { regex = '\\{(\\w+://\\S+)\\}',   format = '$1', highlight = 1 })
table.insert(config.hyperlink_rules, { regex = '<(\\w+://\\S+)>',       format = '$1', highlight = 1 })

-- Keybindings
config.keys = {
  -- Ctrl+Backspace: delete whole line
  { key = 'Backspace', mods = 'CTRL', action = wezterm.action.SendString('\x15') },
  -- Ctrl+Delete: delete word forward
  { key = 'Delete', mods = 'CTRL', action = wezterm.action.SendString('\x1b[3;5~') },
  -- Ctrl+Shift+X: enter copy mode for vim-like selection
  { key = 'X', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateCopyMode },
}

-- Start maximized
wezterm.on('gui-startup', function()
  local _, _, window = wezterm.mux.spawn_window {}
  window:gui_window():maximize()
end)

return config
