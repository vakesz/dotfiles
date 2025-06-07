#!/bin/bash
set -Eeuo pipefail
trap 'error "Error on line $LINENO"; exit 1' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
Setup dotfiles on macOS.

Options:
  --help      Show this help message and exit

Preconditions:
  Xcode Command Line Tools should be installed
EOF
}

# Handle flags
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

install_xcode_tools() {
    if ! xcode-select -p &> /dev/null; then
        log "Installing Xcode Command Line Tools"
        xcode-select --install
        log "Please complete the Xcode installation and re-run this script"
        exit 0
    fi
}

backup_dotfiles() {
    log "Backing up existing dotfiles"
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    for file in .gitconfig .zshrc .bashrc; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_DIR/"
        fi
    done
}

install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for current session
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

install_packages() {
    log "Installing essential packages via Homebrew"
    
    # Update Homebrew
    brew update
    
    # Define packages as an array
    PACKAGES=(
        git neovim python3 node golang rust
        wget curl htop tree jq unzip zip
        ripgrep fd bat fzf bottom hyperfine
        lazygit delta cmake clang-format
        font-jetbrains-mono-nerd-font
    )

    # Install packages
    brew install "${PACKAGES[@]}"
    
    # Install casks (GUI applications)
    CASKS=(
        docker visual-studio-code iterm2 rectangle 
        alt-tab dockdoor hiddenbar latest meetingbar 
        mountain-duck scroll-reverser windows-app 
        spotify keyboardcleantool discord
        vlc firefox
    )
    
    brew install --cask "${CASKS[@]}" || warn "Some casks failed to install"
}

install_tools() {
    # Install Node.js global packages
    if command -v npm &> /dev/null; then
        log "Installing Node.js global packages"
        npm install -g tailwindcss postcss autoprefixer eslint
    fi
}

setup_zsh() {
    log "Setting up ZSH with Oh My Zsh"
    
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    
    # Install plugins
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    for plugin in zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-completions; do
        PLUGIN_DIR="$ZSH_CUSTOM/plugins/$plugin"
        if [ ! -d "$PLUGIN_DIR" ]; then
            case $plugin in
                zsh-autosuggestions) 
                    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR" ;;
                zsh-syntax-highlighting) 
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR" ;;
                fast-syntax-highlighting) 
                    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_DIR" ;;
                zsh-completions) 
                    git clone https://github.com/zsh-users/zsh-completions "$PLUGIN_DIR" ;;
            esac
        fi
    done
}

setup_macos_preferences() {
    log "Configuring macOS preferences"
    
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Show file extensions in Finder
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    
    # Use list view in all Finder windows by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Set Dock icon size to 24px
    defaults write com.apple.dock tilesize -int 24
    
    # Disable resizing of dock with mouse
    defaults write com.apple.Dock size-immutable -bool true
    
    # Disable the "Are you sure you want to open this application?" dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    
    # Enable tap to click for trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    
    # Set faster key repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Show battery percentage in menu bar
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"
    
    # Restart Finder to apply changes
    killall Finder
    
    log "macOS preferences configured"
}

copy_dotfiles() {
    log "Copying dotfiles"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
    
    if [ -f "$DOTFILES_DIR/.gitconfig" ]; then
        cp "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
    fi
    
    if [ -f "$DOTFILES_DIR/.zshrc" ]; then
        cp "$DOTFILES_DIR/.zshrc" ~/.zshrc
    fi
    
    # Copy bin scripts
    mkdir -p "$HOME/bin"
    if [ -d "$DOTFILES_DIR/bin" ]; then
        cp "$DOTFILES_DIR/bin"/* "$HOME/bin/"
        chmod +x "$HOME/bin/"*
    fi
}

finalize_setup() {
    # Set Zsh as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        log "Default shell changed to Zsh"
    fi
    
    # macOS-specific Git configuration
    git config --global credential.helper osxkeychain
    git config --global core.autocrlf input
    
    # Add Homebrew to PATH permanently
    if ! grep -q "/opt/homebrew/bin" ~/.zshrc; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    fi
    
    # Add ~/bin to PATH
    if ! grep -q "$HOME/bin" ~/.zshrc; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
    fi
    
    log "macOS Git and PATH configuration applied"
}

toolkit_post_install_checks() {
    log "Running post-install checks"
    for cmd in git zsh brew node npm python3; do
        if ! command -v $cmd &> /dev/null; then
            warn "$cmd not found in PATH"
        else
            log "$cmd is available at $(which $cmd)"
        fi
    done
    log "Post-install checks completed"
}

# Main execution
log "Starting macOS dotfiles setup"

install_xcode_tools
backup_dotfiles
install_homebrew
install_packages
install_tools
setup_zsh
setup_macos_preferences
copy_dotfiles
finalize_setup
toolkit_post_install_checks

log "macOS setup complete!"
echo -e "${GREEN}Dotfiles have been successfully set up for macOS!${NC}"
echo -e "${YELLOW}Note: Please restart your terminal for all changes to take effect.${NC}"