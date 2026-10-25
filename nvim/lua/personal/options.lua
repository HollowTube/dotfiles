-- Personal options, shared by the standalone config and Omarchy's LazyVim
-- (loaded from lua/config/options.lua). LazyVim already sets undofile,
-- termguicolors and the system clipboard.

local o = vim.o

o.relativenumber = true
o.cursorlineopt = "both"
o.scrolloff = 8

-- WSL clipboard: bridge to Windows clipboard via clip.exe
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = "powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
      ["*"] = "powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
    },
    cache_enabled = 0,
  }
end
