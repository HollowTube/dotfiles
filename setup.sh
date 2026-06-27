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
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
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
if [ "$(uname)" = "Darwin" ]; then
  IS_MAC=true
elif grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
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

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  info "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  skip "zsh-syntax-highlighting already installed"
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

mkdir -p "$HOME/.config"
if [ ! -d "$HOME/.config/nvim" ]; then
  info "Installing NvChad..."
  git clone https://github.com/NvChad/starter "$HOME/.config/nvim"
  ok "NvChad cloned — open nvim to finish installation"
else
  skip "nvim config already exists (~/.config/nvim)"
fi
ln -sf "$DOTFILES_DIR/nvim-custom" "$HOME/.config/nvim/lua"
ok "Linked nvim custom lua config"

# --- .zshrc symlink ---
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
else
  skip "WezTerm — not applicable on remote Linux"
fi
