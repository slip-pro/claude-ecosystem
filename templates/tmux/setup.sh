#!/usr/bin/env bash
# ============================================================
# tmux productivity setup — installer
# ============================================================
# Usage: bash setup.sh
# What it does:
#   1. Checks for tmux, git, fzf
#   2. Installs fzf if missing (needed for sessionx + extrakto)
#   3. Installs TPM (Tmux Plugin Manager)
#   4. Backs up existing ~/.tmux.conf
#   5. Copies new config
#   6. Installs all plugins via TPM
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONF="$SCRIPT_DIR/.tmux.conf"
TARGET="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC} $1"; }
ok()    { echo -e "${GREEN}[ok]${NC} $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
fail()  { echo -e "${RED}[error]${NC} $1"; exit 1; }

# -----------------------------------------------------------
# 1. Check prerequisites
# -----------------------------------------------------------

info "Checking prerequisites..."

command -v tmux >/dev/null 2>&1 || fail "tmux not found. Install it first: sudo apt install tmux"
command -v git  >/dev/null 2>&1 || fail "git not found. Install it first: sudo apt install git"

TMUX_VERSION=$(tmux -V | grep -oP '[\d.]+')
ok "tmux $TMUX_VERSION found"
ok "git found"

# -----------------------------------------------------------
# 2. Install fzf if missing
# -----------------------------------------------------------

if command -v fzf >/dev/null 2>&1; then
  ok "fzf already installed"
else
  info "fzf not found — installing (needed for sessionx + extrakto)..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update -qq && sudo apt install -y -qq fzf
  elif command -v brew >/dev/null 2>&1; then
    brew install fzf
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm fzf
  else
    info "No package manager detected, installing fzf from git..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-zsh --no-fish
  fi
  ok "fzf installed"
fi

# -----------------------------------------------------------
# 3. Install TPM
# -----------------------------------------------------------

if [ -d "$TPM_DIR" ]; then
  ok "TPM already installed at $TPM_DIR"
else
  info "Installing TPM (Tmux Plugin Manager)..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM installed"
fi

# -----------------------------------------------------------
# 4. Backup existing config
# -----------------------------------------------------------

if [ -f "$TARGET" ]; then
  BACKUP="$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
  warn "Existing config found — backing up to $BACKUP"
  cp "$TARGET" "$BACKUP"
fi

# -----------------------------------------------------------
# 5. Copy new config
# -----------------------------------------------------------

if [ ! -f "$TMUX_CONF" ]; then
  fail ".tmux.conf not found at $TMUX_CONF"
fi

cp "$TMUX_CONF" "$TARGET"
ok "Config copied to $TARGET"

# -----------------------------------------------------------
# 6. Install plugins via TPM
# -----------------------------------------------------------

info "Installing tmux plugins via TPM..."
"$TPM_DIR/bin/install_plugins"
ok "All plugins installed"

# -----------------------------------------------------------
# Done
# -----------------------------------------------------------

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} tmux setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Quick reference:"
echo "  prefix = Ctrl+b (default)"
echo ""
echo "  Ctrl+\\        Visual menus (tmux-menus)"
echo "  prefix + o    Fuzzy session switcher (sessionx)"
echo "  prefix + Tab  Fuzzy text grab (extrakto)"
echo "  prefix + I    Install/update plugins (TPM)"
echo "  prefix + C-s  Save sessions (resurrect)"
echo "  prefix + C-r  Restore sessions (resurrect)"
echo "  prefix + |    Split horizontal"
echo "  prefix + -    Split vertical"
echo "  prefix + r    Reload config"
echo ""
echo "Sessions auto-save every 15 min and restore on tmux start."
echo ""
if tmux info >/dev/null 2>&1; then
  warn "tmux is running — run 'tmux source ~/.tmux.conf' to reload,"
  warn "then prefix + I to ensure plugins are loaded."
else
  info "Start tmux with: tmux new -s main"
fi
