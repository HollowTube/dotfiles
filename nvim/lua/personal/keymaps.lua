-- Personal keymaps (loaded from lua/config/keymaps.lua). LazyVim already
-- covers the rest of the old NvChad setup: <C-hjkl> window moves, H/L buffer
-- switching, <A-j>/<A-k> line moves and <leader>gg for lazygit.

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
