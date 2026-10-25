-- Catppuccin Mocha, matching the WezTerm fallback. On Omarchy, the theme
-- comes from Omarchy instead (setup.sh doesn't link this file there).
return {
  { "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000 },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
