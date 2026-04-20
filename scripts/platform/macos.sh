#!/usr/bin/env bash
#
# Optional macOS setup for this dotfiles repo.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASSETS_DIR="$REPO_ROOT/assets/macos"

source "$REPO_ROOT/scripts/lib/common.sh"

require_macos() {
    [[ "$OSTYPE" == darwin* ]] || {
        error "This script is for macOS only"
        exit 1
    }
}

ensure_xcode_cli_tools() {
    if xcode-select -p >/dev/null 2>&1; then
        info "Xcode Command Line Tools already installed"
        return 0
    fi

    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    success "Installation requested"
}

ensure_rosetta() {
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

apply_macos_defaults() {
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
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Panels
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

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
    defaults write com.apple.spaces spans-displays -bool false

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

    # Siri (Apple Intelligence features in Xcode remain available)
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    defaults write com.apple.Siri StatusMenuVisible -bool false
    defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false

    # Animation
    defaults write com.apple.universalaccess reduceMotion -bool true
    defaults write com.apple.dock launchanim -bool true
    defaults write com.apple.dock expose-animation-duration -float 0.1
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

    # Time Machine
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    success "macOS defaults applied"
}

configure_power_management() {
    info "Configuring power management..."

    sudo pmset -b sleep 60 displaysleep 15
    sudo pmset -c sleep 0 displaysleep 30
    sudo pmset -a powernap 0

    success "Power management configured"
}

install_keyboard_layout() {
    info "Installing Hungarian keyboard layout..."
    mkdir -p "$HOME/Library/Keyboard Layouts"
    cp "$ASSETS_DIR/hungarian-win.keylayout" "$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    success "Keyboard layout installed"
}

configure_spotlight_exclusions() {
    info "Excluding high-churn dev paths from Spotlight..."

    local exclusion_paths=(
        "$HOME/Library/Developer/Xcode/DerivedData"
        "$HOME/.cache"
    )

    for path in "${exclusion_paths[@]}"; do
        [[ -d "$path" ]] || continue
        touch "$path/.metadata_never_index"
    done

    success "Spotlight exclusions applied"
}


main() {
    require_macos

    info "macOS setup"

    confirm "Install Xcode Command Line Tools if needed?" && ensure_xcode_cli_tools
    confirm "Install Rosetta on Apple Silicon if needed?" && ensure_rosetta
    confirm "Apply macOS defaults?" && apply_macos_defaults
    confirm "Configure power management?" && configure_power_management
    confirm "Exclude high-churn dev paths from Spotlight?" && configure_spotlight_exclusions
    confirm "Install the custom Hungarian keyboard layout?" && install_keyboard_layout

    success "Done!"
}

main "$@"
