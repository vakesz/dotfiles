#!/usr/bin/env bash
#
# Optional macOS setup for this dotfiles repo.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASSETS_DIR="$REPO_ROOT/assets/macos"

source "$REPO_ROOT/scripts/lib/common.sh"

xcode_cli_tools_installed() {
    xcode-select -p >/dev/null 2>&1
}

install_xcode_cli_tools() {
    info "Requesting Xcode Command Line Tools installation..."
    if xcode-select --install 2>/dev/null; then
        success "Xcode Command Line Tools installation requested"
    else
        warn "Unable to request Xcode Command Line Tools installation"
        info "Install manually with: xcode-select --install"
    fi
}

rosetta_installed() {
    pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1
}

install_rosetta() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        info "Not Apple Silicon; skipping Rosetta"
        return 0
    fi

    if rosetta_installed; then
        info "Rosetta already installed"
        return 0
    fi

    info "Installing Rosetta..."
    if softwareupdate --install-rosetta --agree-to-license; then
        success "Rosetta installed"
    else
        warn "Rosetta installation did not complete"
        return 1
    fi
}

apply_macos_defaults() {
    info "Applying macOS defaults..."

    # Finder
    defaults write com.apple.finder AppleShowAllFiles -bool false
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
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
    local corner
    for corner in tl tr bl br; do
        defaults write com.apple.dock "wvous-${corner}-corner" -int 0
        defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
    done

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
    defaults write com.apple.universalaccess reduceMotion -bool false
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

    sudo -v
    sudo pmset -b sleep 60 displaysleep 15
    sudo pmset -c sleep 0 displaysleep 30
    sudo pmset -a powernap 0

    success "Power management configured"
}

keyboard_layout_already_installed() {
    local target="$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    [[ -f "$target" ]] && cmp -s "$ASSETS_DIR/hungarian-win.keylayout" "$target"
}

install_keyboard_layout() {
    info "Installing Hungarian keyboard layout..."
    mkdir -p "$HOME/Library/Keyboard Layouts"
    cp "$ASSETS_DIR/hungarian-win.keylayout" "$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    success "Keyboard layout installed"
}

spotlight_exclusions_already_applied() {
    local path
    for path in "$HOME/Library/Developer/Xcode/DerivedData" "$HOME/.cache"; do
        [[ -d "$path" ]] || continue
        [[ -f "$path/.metadata_never_index" ]] || return 1
    done
    return 0
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

llvm_dlltool_symlinked() {
    local llvm_prefix="" target=""
    llvm_prefix="$(brew --prefix llvm 2>/dev/null)" || return 1
    target="$HOME/.local/bin/dlltool"
    [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$llvm_prefix/bin/dlltool" ]]
}

setup_llvm_dlltool_symlink() {
    local llvm_prefix="" target=""
    llvm_prefix="$(brew --prefix llvm 2>/dev/null)" || {
        warn "LLVM not installed via Homebrew; skipping dlltool symlink"
        return 1
    }
    target="$HOME/.local/bin/dlltool"
    mkdir -p "$(dirname "$target")"
    ln -sf "$llvm_prefix/bin/dlltool" "$target"
    success "Symlinked ~/.local/bin/dlltool -> $llvm_prefix/bin/dlltool"
}

main() {
    require_platform macos

    info "macOS setup"

    prompt_if_missing \
        xcode_cli_tools_installed \
        install_xcode_cli_tools \
        "Install Xcode Command Line Tools?" \
        "Xcode Command Line Tools already installed"

    if [[ "$(uname -m)" == "arm64" ]]; then
        prompt_if_missing \
            rosetta_installed \
            install_rosetta \
            "Install Rosetta?" \
            "Rosetta already installed"
    else
        info "Not Apple Silicon; skipping Rosetta"
    fi

    confirm_and_run "Apply macOS defaults?" apply_macos_defaults
    confirm_and_run "Configure power management?" configure_power_management
    prompt_if_missing \
        spotlight_exclusions_already_applied \
        configure_spotlight_exclusions \
        "Exclude high-churn dev paths from Spotlight?" \
        "Spotlight exclusions already applied"
    prompt_if_missing \
        keyboard_layout_already_installed \
        install_keyboard_layout \
        "Install the custom Hungarian keyboard layout?" \
        "Custom Hungarian keyboard layout already installed"

    prompt_if_missing \
        llvm_dlltool_symlinked \
        setup_llvm_dlltool_symlink \
        "Symlink LLVM dlltool into ~/.local/bin for Wine builds?" \
        "LLVM dlltool symlink already in place"

    offer_javascript_toolchain_setup

    # The office-tweaks script self-gates with its own confirm prompt.
    "$REPO_ROOT/scripts/platform/macos-office-tweaks.sh"

    success "macOS setup complete"
}

main "$@"
