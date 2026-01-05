#!/usr/bin/env bash
#
# Dotfiles installer - symlinks configs via GNU Stow with optional OS tweaks.
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging
info()    { printf '\033[34m[INFO]\033[0m %s\n' "$1"; }
success() { printf '\033[32m[OK]\033[0m %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m %s\n' "$1"; }
error()   { printf '\033[31m[ERROR]\033[0m %s\n' "$1"; }

# Platform detection
detect_platform() {
    case "$OSTYPE" in
        darwin*)  PLATFORM="macos" ;;
        linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                PLATFORM="wsl"
            else
                PLATFORM="linux"
            fi ;;
        *)        PLATFORM="unknown" ;;
    esac
    info "Detected platform: $PLATFORM"
}

# macOS tweaks - Finder, keyboard, Dock defaults
apply_macos_tweaks() {
    info "Applying macOS defaults..."

    # Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Keyboard
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Dock
    defaults write com.apple.dock tilesize -int 36
    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock show-process-indicators -bool true

    # Screenshots
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write com.apple.screencapture type -string "png"

    # Tips
    defaults write com.apple.tips TipsEnabled -bool false

    # Restart affected services
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    success "macOS defaults applied"
}

# Linux/WSL tweaks - locale and shell setup
apply_linux_tweaks() {
    # Setup locale
    if locale -a 2>/dev/null | grep -qE '^en_US\.UTF-8$|^en_US\.utf8$'; then
        info "Locale en_US.UTF-8 already available"
    else
        info "Installing en_US.UTF-8 locale..."
        sudo apt-get update -qq
        sudo apt-get install -y locales
        sudo locale-gen en_US.UTF-8
        success "Locale en_US.UTF-8 generated"
    fi
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

    # Set zsh as default shell
    command -v zsh &>/dev/null || { warn "zsh not installed"; return 0; }
    [[ "$(basename "$SHELL")" == "zsh" ]] && { info "Shell is already zsh"; return 0; }

    info "Changing default shell to zsh..."
    grep -q "$(which zsh)" /etc/shells 2>/dev/null || which zsh | sudo tee -a /etc/shells > /dev/null

    if chsh -s "$(which zsh)"; then
        success "Default shell changed to zsh (log out and back in to apply)"
    else
        error "Failed to change shell"
        return 1
    fi
}

# GNU Stow symlinks
apply_stow() {
    command -v stow &>/dev/null || { error "GNU Stow not installed"; return 1; }
    info "Applying dotfiles via GNU Stow..."
    stow -v --restow -d "$DOTFILES_DIR" -t "$HOME" . && success "Stow completed"
}

main() {
    info "Dotfiles installer"
    detect_platform

    read -rn1 -p $'\nApply OS tweaks? (y/N) ' apply_tweaks
    echo ""
    if [[ "$apply_tweaks" =~ ^[Yy]$ ]]; then
        case "$PLATFORM" in
            macos) apply_macos_tweaks ;;
            linux|wsl) apply_linux_tweaks ;;
            *) warn "No tweaks for platform: $PLATFORM" ;;
        esac
    fi

    apply_stow
    success "Done!"
}

main "$@"
