#!/usr/bin/env bash
#
# Optional macOS machine setup for this dotfiles repo.
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Logging
info()    { printf '\033[34m[INFO]\033[0m %s\n' "$1"; }
success() { printf '\033[32m[OK]\033[0m %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m %s\n' "$1"; }
error()   { printf '\033[31m[ERROR]\033[0m %s\n' "$1"; }

# Interactive prompt helper
ask() {
    local answer="n"
    read -r -n 1 -p $'\n'"$1"$' (y/N) ' answer || true
    echo ""
    [[ "$answer" =~ ^[Yy]$ ]]
}

require_macos() {
    [[ "$OSTYPE" == darwin* ]] || { error "This script is for macOS only"; exit 1; }
}

apply_macos_tweaks() {
    info "Applying macOS defaults..."

    # Finder
    defaults write com.apple.finder AppleShowAllFiles -bool false
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "icnv"
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"
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
    defaults write com.apple.dock showAppExposeGestureEnabled -bool true

    # Dock
    defaults write com.apple.dock tilesize -int 32
    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock show-process-indicators -bool true
    defaults write com.apple.dock autohide -bool false
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock size-immutable -bool true

    # Mission Control
    defaults write com.apple.dock mru-spaces -bool false
    defaults write com.apple.dock expose-group-apps -bool true
    defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool true

    # Hot corners: all disabled (0 = no action)
    defaults write com.apple.dock wvous-tl-corner -int 0
    defaults write com.apple.dock wvous-tl-modifier -int 0
    defaults write com.apple.dock wvous-tr-corner -int 0
    defaults write com.apple.dock wvous-tr-modifier -int 0
    defaults write com.apple.dock wvous-bl-corner -int 0
    defaults write com.apple.dock wvous-bl-modifier -int 0
    defaults write com.apple.dock wvous-br-corner -int 0
    defaults write com.apple.dock wvous-br-modifier -int 0

    # Screenshots
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write com.apple.screencapture type -string "png"

    # Safari Developer (may fail without Full Disk Access due to sandbox)
    defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true 2>/dev/null || true
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Tips
    defaults write com.apple.tips TipsEnabled -bool false
    defaults write com.apple.tips CloudKitSyncingEnabled -bool false
    defaults write com.apple.tips NotificationsEnabled -bool false

    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    success "macOS defaults applied"

    if ! xcode-select -p >/dev/null 2>&1; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
    fi
}

install_keyboard_layout() {
    info "Installing Hungarian keyboard layout..."
    mkdir -p "$HOME/Library/Keyboard Layouts"
    cp "$DOTFILES_DIR/apps/Hungarian_Win.keylayout" "$HOME/Library/Keyboard Layouts/"
    success "Keyboard layout installed"
}

install_rosetta() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        info "Not Apple Silicon; skipping Rosetta"
        return 0
    fi

    if /usr/bin/pgrep -q oahd; then
        info "Rosetta already installed"
        return 0
    fi

    info "Installing Rosetta..."
    softwareupdate --install-rosetta --agree-to-license
    success "Rosetta installed"
}

setup_podman() {
    if ! command -v podman >/dev/null 2>&1; then
        warn "podman not found; skipping Podman setup"
        return 0
    fi

    if ! podman machine inspect >/dev/null 2>&1; then
        info "Initializing Podman machine..."
        podman machine init \
            --cpus 6 \
            --memory 8192 \
            --disk-size 60 \
            --rootful
        success "Podman machine initialized"
    else
        info "Podman machine already exists"
    fi

    if ! podman machine inspect --format '{{.State}}' 2>/dev/null | grep -q "running"; then
        info "Starting Podman machine..."
        podman machine start
        success "Podman machine started"
    else
        info "Podman machine already running"
    fi
}

main() {
    require_macos

    info "Optional macOS setup"

    ask "Apply macOS defaults?" && apply_macos_tweaks
    ask "Install Hungarian keyboard layout?" && install_keyboard_layout
    ask "Install Rosetta for amd64 emulation?" && install_rosetta
    ask "Set up Podman container runtime?" && setup_podman

    success "Done!"
}

main "$@"
