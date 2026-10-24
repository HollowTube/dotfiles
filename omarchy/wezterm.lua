-- WezTerm's Wayland app-id isn't in Omarchy's terminal list; tag it so
-- SUPER+C/V send terminal copy/paste instead of Ctrl+C/Ctrl+V.
o.window("org\\.wezfurlong\\.wezterm", { tag = "+terminal" })
