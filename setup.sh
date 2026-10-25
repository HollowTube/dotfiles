#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo "[INFO]  $*"; }
ok()    { echo "[OK]    $*"; }
skip()  { echo "[SKIP]  $*"; }
warn()  { echo "[WARN]  $*"; }

# Detect package manager
pkg_install() {
  if command -v brew &>/dev/null; then
    brew install "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$@"
  else
    warn "No supported package manager found — install $* manually"
    return 1
  fi
}

IS_WSL=false
IS_MAC=false
IS_REMOTE_LINUX=false
IS_DESKTOP_LINUX=false
if [ "$(uname)" = "Darwin" ]; then
  IS_MAC=true
elif grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
elif [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
  IS_DESKTOP_LINUX=true
else
  IS_REMOTE_LINUX=true
fi

# --- zsh ---
if ! command -v zsh &>/dev/null; then
  info "Installing zsh..."
  pkg_install zsh
else
  skip "zsh already installed ($(zsh --version))"
fi

# --- .zshrc symlink (before Oh My Zsh, so its installer doesn't drop a template in the way) ---
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  if [ ! -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    ok "Linked ~/.zshrc → $DOTFILES_DIR/.zshrc"
  else
    skip "~/.zshrc already exists — leaving it. Reference: $DOTFILES_DIR/.zshrc"
  fi
else
  skip "No .zshrc in dotfiles dir — skipping symlink"
fi

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed"
else
  skip "Oh My Zsh already installed"
fi

# --- zsh plugins ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  skip "zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
  info "Installing fast-syntax-highlighting..."
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
else
  skip "fast-syntax-highlighting already installed"
fi

# --- xclip (clipboard — only useful on Linux with a display, skip headless) ---
if [ "$IS_REMOTE_LINUX" = false ] && [ "$IS_MAC" = false ]; then
  if ! command -v xclip &>/dev/null; then
    info "Installing xclip..."
    pkg_install xclip || true
  else
    skip "xclip already installed"
  fi
fi

# --- zoxide ---
if ! command -v zoxide &>/dev/null; then
  info "Installing zoxide..."
  if command -v brew &>/dev/null; then
    brew install zoxide
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y zoxide
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y zoxide
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm zoxide
  else
    warn "Could not install zoxide — install manually from https://github.com/ajeetdsouza/zoxide"
  fi
else
  skip "zoxide already installed ($(zoxide --version))"
fi

# --- lazygit ---
if ! command -v lazygit &>/dev/null; then
  info "Installing lazygit..."
  if command -v brew &>/dev/null; then
    brew install lazygit
  elif command -v dnf &>/dev/null; then
    sudo dnf copr enable atim/lazygit -y && sudo dnf install -y lazygit
  else
    LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin/lazygit
  fi
else
  skip "lazygit already installed ($(lazygit --version | grep -o 'version=[^ ,]*'))"
fi

# --- btop ---
if ! command -v btop &>/dev/null; then
  info "Installing btop..."
  pkg_install btop
else
  skip "btop already installed"
fi

# --- tmux ---
if ! command -v tmux &>/dev/null; then
  info "Installing tmux..."
  pkg_install tmux
else
  skip "tmux already installed ($(tmux -V))"
fi

# --- nvim ---
if ! command -v nvim &>/dev/null; then
  info "Installing neovim..."
  pkg_install neovim
else
  skip "nvim already installed ($(nvim --version | head -1))"
fi

# --- config symlinks ---
if [ ! -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
  ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
  ok "Linked ~/.tmux.conf"
else
  skip "~/.tmux.conf already exists — leaving it. Reference: $DOTFILES_DIR/.tmux.conf"
fi

# tmux also loads ~/.config/tmux/tmux.conf after ~/.tmux.conf, so one there
# (Omarchy ships its own) would override ours — point it at ours instead
TMUX_XDG_CONF="$HOME/.config/tmux/tmux.conf"
if [ -e "$TMUX_XDG_CONF" ] && [ ! -L "$TMUX_XDG_CONF" ]; then
  TMUX_BAK="$TMUX_XDG_CONF.bak.$(date +%Y%m%d%H%M%S)"
  mv "$TMUX_XDG_CONF" "$TMUX_BAK"
  warn "Moved existing tmux config to $TMUX_BAK"
fi
if [ -e "$TMUX_XDG_CONF" ] || [ -n "$TMUX_BAK" ]; then
  ln -sf "$DOTFILES_DIR/.tmux.conf" "$TMUX_XDG_CONF"
  ok "Linked ~/.config/tmux/tmux.conf"
fi

mkdir -p "$HOME/.config"
NVIM_DIR="$HOME/.config/nvim"
if [ -d /usr/share/omarchy ] && [ -f "$NVIM_DIR/lazyvim.json" ] && [ ! -L "$NVIM_DIR" ]; then
  # Omarchy owns ~/.config/nvim (its theme.lua symlink keeps nvim in sync with
  # the system theme), so only hook the personal settings into it
  ln -sfn "$DOTFILES_DIR/nvim/lua/personal" "$NVIM_DIR/lua/personal"
  for f in options keymaps; do
    if ! grep -q "require(\"personal.$f\")" "$NVIM_DIR/lua/config/$f.lua"; then
      printf '\nrequire("personal.%s")\n' "$f" >> "$NVIM_DIR/lua/config/$f.lua"
    fi
  done
  ok "Hooked personal nvim settings into Omarchy's LazyVim"
else
  if [ -e "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
    NVIM_BAK="$NVIM_DIR.bak.$(date +%Y%m%d%H%M%S)"
    mv "$NVIM_DIR" "$NVIM_BAK"
    warn "Moved existing nvim config to $NVIM_BAK"
  fi
  ln -sfn "$DOTFILES_DIR/nvim" "$NVIM_DIR"
  ok "Linked ~/.config/nvim → $DOTFILES_DIR/nvim (LazyVim) — open nvim to install plugins"
fi

# --- Claude Code status line (model, context, 5h/7d usage limits) ---
if ! command -v jq &>/dev/null; then
  info "Installing jq (used by the Claude Code status line)..."
  pkg_install jq
else
  skip "jq already installed"
fi

mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
[ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
if jq -e '.statusLine' "$CLAUDE_SETTINGS" &>/dev/null; then
  skip "Claude Code already has a statusLine — leaving it. Reference: $DOTFILES_DIR/claude/statusline.sh"
else
  # Merge rather than overwrite: Claude Code keeps its own settings in this file
  jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp"
  mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
  ok "Enabled Claude Code status line"
fi

ok "Setup complete! Restart your shell or run: source ~/.zshrc"
if command -v zsh &>/dev/null && [ "$(basename "$SHELL")" != "zsh" ]; then
  warn "zsh is not your default shell — run: chsh -s \$(which zsh)"
fi

# --- WezTerm ---
if [ "$IS_MAC" = true ]; then
  if ! command -v wezterm &>/dev/null; then
    info "Installing WezTerm..."
    brew install --cask wezterm
  else
    skip "WezTerm already installed"
  fi
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
  ok "Linked ~/.wezterm.lua"
elif [ "$IS_WSL" = true ]; then
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  if [ -n "$WIN_USER" ] && [ -d "/mnt/c/Users/$WIN_USER" ]; then
    cp "$DOTFILES_DIR/wezterm/.wezterm.lua" "/mnt/c/Users/$WIN_USER/.wezterm.lua"
    ok "Copied .wezterm.lua to Windows user dir (C:\\Users\\$WIN_USER)"
  else
    warn "Could not detect Windows user — copy dotfiles/wezterm/.wezterm.lua to C:\\Users\\<you>\\ manually"
  fi
elif [ "$IS_DESKTOP_LINUX" = true ]; then
  if ! command -v wezterm &>/dev/null; then
    info "Installing WezTerm..."
    if command -v dnf &>/dev/null; then
      sudo dnf copr enable wezfurlong/wezterm-nightly -y && sudo dnf install -y wezterm
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm wezterm
    elif command -v flatpak &>/dev/null; then
      flatpak install -y flathub org.wezfurlong.wezterm
    else
      warn "Could not install WezTerm — see https://wezterm.org/install/linux.html"
    fi
  else
    skip "WezTerm already installed"
  fi
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
  ok "Linked ~/.wezterm.lua"

  if ! fc-list | grep -q "JetBrainsMono Nerd Font"; then
    info "Installing JetBrainsMono Nerd Font..."
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    mkdir -p "$FONT_DIR"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
      | tar -xJ -C "$FONT_DIR" --wildcards '*.ttf'
    fc-cache -f "$FONT_DIR"
    ok "JetBrainsMono Nerd Font installed"
  else
    skip "JetBrainsMono Nerd Font already installed"
  fi
else
  skip "WezTerm — not applicable on remote Linux"
fi

# --- Omarchy: make WezTerm a first-class terminal ---
if [ -d /usr/share/omarchy ] && command -v wezterm &>/dev/null; then
  # Desktop entry override: lets xdg-terminal-exec pass --app-id/--dir/-e to WezTerm,
  # so Omarchy's floating TUIs (btop, installers) keep their window class
  mkdir -p "$HOME/.local/share/applications"
  ln -sf "$DOTFILES_DIR/omarchy/org.wezfurlong.wezterm.desktop" \
    "$HOME/.local/share/applications/org.wezfurlong.wezterm.desktop"
  ok "Linked WezTerm desktop entry override"

  # Default terminal for SUPER+RETURN and Omarchy menus
  TERMINALS_LIST="$HOME/.config/hyprland-xdg-terminals.list"
  if [ ! -f "$TERMINALS_LIST" ] || [ -L "$TERMINALS_LIST" ]; then
    ln -sf "$DOTFILES_DIR/omarchy/hyprland-xdg-terminals.list" "$TERMINALS_LIST"
    ok "Set WezTerm as default terminal"
  else
    skip "$TERMINALS_LIST already exists — leaving it. Reference: $DOTFILES_DIR/omarchy/hyprland-xdg-terminals.list"
  fi

  # Hyprland rule tagging WezTerm as a terminal (universal copy/paste)
  ln -sf "$DOTFILES_DIR/omarchy/wezterm.lua" "$HOME/.config/hypr/wezterm.lua"
  if ! grep -q 'require("hypr.wezterm")' "$HOME/.config/hypr/hyprland.lua"; then
    printf '\nrequire("hypr.wezterm")\n' >> "$HOME/.config/hypr/hyprland.lua"
  fi
  hyprctl reload &>/dev/null || true
  ok "Linked Hyprland WezTerm rules"
fi
