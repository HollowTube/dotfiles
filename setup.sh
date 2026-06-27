#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo "[INFO]  $*"; }
ok()    { echo "[OK]    $*"; }
skip()  { echo "[SKIP]  $*"; }

# --- Oh My Zsh ---
# Note: the OMZ installer automatically backs up any existing ~/.zshrc to
# ~/.zshrc.pre-oh-my-zsh before replacing it, so the original is always safe.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed (original ~/.zshrc backed up to ~/.zshrc.pre-oh-my-zsh)"
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

# --- xclip (clipboard over SSH on Linux) ---
if [ "$(uname)" = "Linux" ] && ! grep -qi microsoft /proc/version 2>/dev/null; then
  if ! command -v xclip &>/dev/null; then
    info "Installing xclip for clipboard support..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get install -y xclip
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm xclip
    else
      echo "[WARN]  Could not install xclip — clipboard may not work over SSH"
    fi
  else
    skip "xclip already installed"
  fi
fi

# --- tmux ---
if ! command -v tmux &>/dev/null; then
  info "Installing tmux..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y tmux
  elif command -v brew &>/dev/null; then
    brew install tmux
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm tmux
  else
    echo "[WARN]  Could not detect package manager — install tmux manually"
  fi
else
  skip "tmux already installed ($(tmux -V))"
fi

# --- nvim ---
if ! command -v nvim &>/dev/null; then
  info "Installing neovim..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y neovim
  elif command -v brew &>/dev/null; then
    brew install neovim
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm neovim
  else
    echo "[WARN]  Could not detect package manager — install nvim manually"
  fi
else
  skip "nvim already installed ($(nvim --version | head -1))"
fi

# --- config symlinks ---
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
ok "Linked ~/.tmux.conf"

mkdir -p "$HOME/.config"
if [ ! -d "$HOME/.config/nvim" ]; then
  info "Installing NvChad..."
  git clone https://github.com/NvChad/starter "$HOME/.config/nvim"
  ok "NvChad cloned — open nvim to finish installation"
else
  skip "nvim config already exists (~/.config/nvim)"
fi
# Overlay custom lua config (symlink each file so dotfiles stay in sync)
ln -sf "$DOTFILES_DIR/nvim-custom" "$HOME/.config/nvim/lua"
ok "Linked nvim custom lua config"

# --- .zshrc symlink ---
# OMZ already backed up the pre-existing ~/.zshrc to ~/.zshrc.pre-oh-my-zsh.
# We just replace whatever is there now with a symlink to our dotfiles version.
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  ok "Linked ~/.zshrc → $DOTFILES_DIR/.zshrc"
else
  skip "No .zshrc in dotfiles dir — skipping symlink"
fi

ok "Setup complete! Restart your shell or run: source ~/.zshrc"

# --- WezTerm ---
if [ "$(uname)" = "Darwin" ]; then
  # macOS: install via brew and symlink config
  if ! command -v wezterm &>/dev/null; then
    info "Installing WezTerm..."
    brew install --cask wezterm
  else
    skip "WezTerm already installed"
  fi
  ln -sf "$DOTFILES_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
  ok "Linked ~/.wezterm.lua"
else
  # WSL: copy config to Windows user directory
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  if [ -n "$WIN_USER" ] && [ -d "/mnt/c/Users/$WIN_USER" ]; then
    cp "$DOTFILES_DIR/wezterm/.wezterm.lua" "/mnt/c/Users/$WIN_USER/.wezterm.lua"
    ok "Copied .wezterm.lua to Windows user dir (C:\\Users\\$WIN_USER)"
  else
    echo "[WARN]  Could not detect Windows user — copy dotfiles/wezterm/.wezterm.lua to C:\\Users\\<you>\\ manually"
  fi
fi
