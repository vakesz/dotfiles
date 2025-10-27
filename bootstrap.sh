#!/usr/bin/env bash
# bootstrap.sh - Simple dotfiles installer using GNU Stow

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
        OS="wsl"
    else
        OS="linux"
    fi
else
    error "Unsupported OS: $OSTYPE"
    exit 1
fi

log "Detected OS: $OS"

# Check if we're in the dotfiles directory
if [[ ! -f "$DOTFILES_DIR/Brewfile" ]]; then
    error "Must run from dotfiles directory"
    exit 1
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ "$OS" == "macos" ]]; then
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        if [[ -d /home/linuxbrew/.linuxbrew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# Install packages from Brewfile
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    log "Installing packages from Brewfile..."
    cd "$DOTFILES_DIR"
    if brew bundle; then
        success "Packages installed"
    else
        warn "Some packages may have failed to install"
    fi
else
    warn "Brewfile not found, skipping package installation"
fi

# Clean up old broken symlinks from previous installation methods
log "Cleaning up old broken symlinks..."
for link in "$HOME/.gitconfig" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.tmux.conf" \
            "$HOME/.gitignore_global" "$HOME/.gitconfig.platform" \
            "$HOME/.config/starship.toml"; do
    if [[ -L "$link" ]] && ! readlink -e "$link" >/dev/null 2>&1; then
        log "  Removing broken symlink: $(basename "$link")"
        rm -f "$link"
    fi
done

# Stow packages
log "Creating symlinks with GNU Stow..."
cd "$DOTFILES_DIR"

# List of packages to stow
PACKAGES=(
    "zsh"
    "git"
    "nvim"
    "tmux"
    "starship"
    "shell-profile"
)

for package in "${PACKAGES[@]}"; do
    if [[ -d "$package" ]]; then
        log "  Stowing $package..."
        if stow -v -t "$HOME" "$package" 2>&1 | grep -q "LINK"; then
            success "  Linked $package"
        else
            success "  $package already linked"
        fi
    fi
done

# Set up platform-specific Git config
log "Setting up platform-specific Git configuration..."
if [[ "$OS" == "macos" ]]; then
    if [[ -f "$HOME/.gitconfig.macos" ]]; then
        ln -sf "$HOME/.gitconfig.macos" "$HOME/.gitconfig.platform"
        success "Linked Git config for macOS"
    else
        warn "macOS Git config not found"
    fi
elif [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
    if [[ -f "$HOME/.gitconfig.linux" ]]; then
        ln -sf "$HOME/.gitconfig.linux" "$HOME/.gitconfig.platform"
        success "Linked Git config for Linux/WSL"
    else
        warn "Linux Git config not found"
    fi
fi

# Source security/permissions library and set secure permissions
if [[ -f "$DOTFILES_DIR/lib/permissions.sh" ]]; then
    log "Setting secure file permissions..."
    source "$DOTFILES_DIR/lib/permissions.sh"
    set_secure_permissions "$DOTFILES_DIR" 2>/dev/null || warn "Some permissions could not be set"
    success "Secure permissions applied"
fi

echo ""
success "Dotfiles installation complete!"
echo ""
log "Next steps:"
log "  1. Restart your shell: exec \$SHELL"
log "  2. Or source your config: source ~/.zshrc"
log ""
log "To add machine-specific configs (not in git):"
log "  • Shell: Create ~/.zshrc.local"
log "  • Git:   Edit ~/.gitconfig.local"
log ""
log "To disable a module:"
log "  cd ~/dotfiles && stow -D <package-name>"
log ""
log "To re-enable a module:"
log "  cd ~/dotfiles && stow <package-name>"
