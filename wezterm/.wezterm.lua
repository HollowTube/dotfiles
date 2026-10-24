local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local is_mac = wezterm.target_triple:find('darwin') ~= nil
local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_linux = not is_mac and not is_windows

-- On Windows, default into the Fedora WSL instance
if is_windows then
  config.default_domain = 'WSL:FedoraLinux-44'
end

-- Trying out zsh in WezTerm before making it the login shell (chsh -s /usr/bin/zsh);
-- drop this once $SHELL is zsh
if is_linux and os.getenv('SHELL') ~= '/usr/bin/zsh' and io.open('/usr/bin/zsh') then
  config.default_prog = { '/usr/bin/zsh', '-l' }
end

-- Font — change to whichever Nerd Font you installed
-- Ctrl+- / Ctrl+= zoom the current window, Ctrl+0 resets
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = is_linux and 10.0 or 12.0

config.scrollback_lines = 10000

-- Colors: follow the current Omarchy theme when there is one, else Catppuccin Mocha
local omarchy_colors = wezterm.home_dir .. '/.local/state/omarchy/current/theme/colors.toml'

local function read_omarchy_colors(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local c = {}
  for line in f:lines() do
    local key, value = line:match('^%s*([%w_]+)%s*=%s*"(#%x+)"')
    if key then c[key] = value end
  end
  f:close()
  if not (c.background and c.foreground) then return nil end

  -- Same mapping Omarchy uses for its foot/alacritty themes
  local fg, bright_fg = c.foreground, c.bright_foreground or c.foreground
  return {
    foreground = fg,
    background = c.background,
    cursor_bg = bright_fg,
    cursor_fg = c.background,
    cursor_border = bright_fg,
    selection_fg = c.selection_foreground or fg,
    selection_bg = c.selection or c.selection_background,
    ansi = { c.background, c.red, c.green, c.yellow, c.blue, c.purple or c.magenta, c.cyan, fg },
    brights = {
      c.muted, c.bright_red or c.red, c.bright_green or c.green, c.bright_yellow or c.yellow,
      c.bright_blue or c.blue, c.bright_magenta or c.magenta, c.bright_cyan or c.cyan, bright_fg,
    },
  }
end

local theme = read_omarchy_colors(omarchy_colors)
if theme then
  config.colors = theme
  -- Reload when `omarchy theme set` rewrites the theme
  wezterm.add_to_config_reload_watch_list(omarchy_colors)
else
  config.color_scheme = 'Catppuccin Mocha'
end

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
-- On Linux, Hyprland already applies window opacity (SUPER+BACKSPACE toggles it)
config.window_background_opacity = is_linux and 1.0 or 0.95  -- 0.0 fully transparent, 1.0 solid
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
config.default_cursor_style = 'SteadyBar'

-- Clickable URLs in brackets, parens, angle brackets etc.
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, { regex = '\\((\\w+://\\S+)\\)',   format = '$1', highlight = 1 })
table.insert(config.hyperlink_rules, { regex = '\\[(\\w+://\\S+)\\]',   format = '$1', highlight = 1 })
table.insert(config.hyperlink_rules, { regex = '\\{(\\w+://\\S+)\\}',   format = '$1', highlight = 1 })
table.insert(config.hyperlink_rules, { regex = '<(\\w+://\\S+)>',       format = '$1', highlight = 1 })

-- Keybindings
if is_mac then
  config.keys = {
    -- Cmd+Backspace: delete whole line (standard macOS)
    { key = 'Backspace', mods = 'CMD',  action = wezterm.action.SendString('\x15') },
    -- Option+Backspace: delete word backward (standard macOS)
    { key = 'Backspace', mods = 'OPT',  action = wezterm.action.SendString('\x17') },
    -- Option+Delete: delete word forward (standard macOS, Fn+Backspace)
    { key = 'Delete',    mods = 'OPT',  action = wezterm.action.SendString('\x1bd') },
    -- Ctrl+Shift+X: copy mode
    { key = 'X', mods = 'CTRL|SHIFT',   action = wezterm.action.ActivateCopyMode },
  }
else
  config.keys = {
    -- Ctrl+Backspace: delete whole line
    { key = 'Backspace', mods = 'CTRL', action = wezterm.action.SendString('\x15') },
    -- Ctrl+Delete: delete word forward
    { key = 'Delete',    mods = 'CTRL', action = wezterm.action.SendString('\x1b[3;5~') },
    -- Ctrl+Shift+X: copy mode
    { key = 'X', mods = 'CTRL|SHIFT',   action = wezterm.action.ActivateCopyMode },
  }
end

if is_windows then
  -- Ctrl+V: paste (Windows-style)
  table.insert(config.keys, { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom('Clipboard') })
end

if is_linux then
  -- Send Shift+Enter / Alt+Shift+Enter as CSI-u, like Omarchy's foot config,
  -- so TUIs can tell them from Enter and tmux can match M-S-Enter
  table.insert(config.keys, { key = 'Enter', mods = 'SHIFT',     action = wezterm.action.SendString('\x1b[13;2u') })
  table.insert(config.keys, { key = 'Enter', mods = 'ALT|SHIFT', action = wezterm.action.SendString('\x1b[13;4u') })
end

-- Start maximized (not on Linux, where Hyprland tiles the window)
if not is_linux then
  wezterm.on('gui-startup', function()
    local _, _, window = wezterm.mux.spawn_window {}
    window:gui_window():maximize()
  end)
end

return config
