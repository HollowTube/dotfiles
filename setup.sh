#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo "[INFO]  $*"; }
ok()    { echo "[OK]    $*"; }
skip()  { echo "[SKIP]  $*"; }

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  skip "Oh My Zsh already installed"
fi

# --- zsh-autosuggestions ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  skip "zsh-autosuggestions already installed"
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

# --- .zshrc symlink ---
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    info "Backing up existing ~/.zshrc to ~/.zshrc.bak"
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi
  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  ok "Linked ~/.zshrc → $DOTFILES_DIR/.zshrc"
else
  skip "No .zshrc in dotfiles dir — skipping symlink"
fi

ok "Setup complete! Restart your shell or run: source ~/.zshrc"
