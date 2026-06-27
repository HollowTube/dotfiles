local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Default to Fedora WSL instance
config.default_domain = 'WSL:FedoraLinux-44'

-- Font — change to whichever Nerd Font you installed
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 12.0

-- Catppuccin Mocha (matches nvim theme)
config.color_scheme = 'Catppuccin Mocha'

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_background_opacity = 0.9  -- 0.0 fully transparent, 1.0 solid
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Cursor
config.default_cursor_style = 'BlinkingBar'

-- Remove the title bar (clean look), keep resize border
config.window_decorations = 'TITLE | RESIZE'

return config
