#!/usr/bin/env bash
#
# macOS-specific setup script
# Run after main installation to configure macOS-specific settings
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions from parent directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

set_log_context "macOS"

# ============================================================================
# macOS System Preferences
# ============================================================================

configure_macos_defaults() {
    log_info "Configuring macOS defaults..."

    # Finder: show hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Finder: show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Finder: show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Finder: show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Finder: use list view in all Finder windows by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Finder: always open folders in list view (overrides per-folder settings)
    defaults write com.apple.finder AlwaysOpenInListView -bool true

    # Finder: keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # Disable .DS_Store files on network volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

    # Disable .DS_Store files on USB volumes
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Disable .DS_Store files creation globally (requires disabling metadata writing)
    defaults write com.apple.desktopservices DSDontWriteStores -bool true

    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Save screenshots to Desktop
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"

    # Save screenshots in PNG format
    defaults write com.apple.screencapture type -string "png"

    # Enable full keyboard access for all controls
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Set fast key repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Disable smart dashes as they're annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution as it's annoying when typing code
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes as they're annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Trackpad: enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Safari: enable developer menu (may fail due to App Sandboxing)
    # Note: Safari's preferences are sandboxed and may require manual configuration
    defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || \
        log_warning "Could not configure Safari (requires manual setup in Safari > Settings > Advanced)"
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true 2>/dev/null || true

    # Safari: disable Java
    defaults write com.apple.Safari WebKitJavaEnabled -bool false 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false 2>/dev/null || true

    # Safari: block pop-up windows
    defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false 2>/dev/null || true

    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    # Dock: set icon size to 36 pixels
    defaults write com.apple.dock tilesize -int 36

    # Dock: change minimize/maximize window effect
    defaults write com.apple.dock mineffect -string "scale"

    # Dock: position on bottom
    defaults write com.apple.dock orientation -string "bottom"

    # Dock: minimize windows into application icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Dock: show indicator lights for open applications
    defaults write com.apple.dock show-process-indicators -bool true

    log_success "macOS defaults configured"
}

# ============================================================================
# Development Tools Setup
# ============================================================================

setup_xcode_tools() {
    if ! xcode-select -p &>/dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warning "Please complete Xcode Command Line Tools installation and re-run this script"
        exit 0
    else
        log_info "Xcode Command Line Tools already installed"
    fi
}

# ============================================================================
# Font Setup
# ============================================================================

install_fonts() {
    log_info "Checking for Nerd Fonts..."

    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        log_info "JetBrains Mono Nerd Font already installed"
    else
        log_info "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
    fi

    log_success "Fonts setup complete"
}

# ============================================================================
# macOS-specific Applications
# ============================================================================

install_macos_apps() {
    log_info "Checking for macOS-specific tools..."

    local tools=("xcodegen" "swiftlint" "swiftformat" "xcbeautify")

    for tool in "${tools[@]}"; do
        if brew list "$tool" &>/dev/null; then
            log_info "$tool already installed"
        else
            log_info "Consider installing $tool: brew install $tool"
        fi
    done
}

# ============================================================================
# Colima Service Setup (Docker Alternative)
# ============================================================================

setup_colima_service() {
    if ! command -v colima &>/dev/null; then
        log_info "Colima not installed, skipping service setup"
        return 0
    fi

    log_info "Setting up Colima service..."

    # Check if Colima service is already running via brew services
    if brew services list | grep -q "^colima.*started"; then
        log_info "Colima service already running"
        return 0
    fi

    # Stop any running Colima instance
    if colima status &>/dev/null; then
        log_info "Stopping existing Colima instance..."
        colima stop 2>/dev/null || true
    fi

    # Enable Colima as a service
    log_info "Enabling Colima as a macOS service..."
    # Try starting via brew services and catch failures. If bootstrap fails, try to remediate.
    brew services start colima || true

    log_success "Colima service configured"
}

# ============================================================================
# Clean Finder View Preferences
# ============================================================================

clean_finder_views() {
    log_info "Cleaning .DS_Store files to reset Finder view preferences..."

    # Remove .DS_Store files from home directory (these store per-folder view settings)
    find ~ -name ".DS_Store" -type f -delete 2>/dev/null || true

    # Clear Finder preferences cache
    rm -f ~/Library/Preferences/com.apple.finder.plist.lockfile 2>/dev/null || true

    log_success "Finder view preferences cleaned"
}


# ============================================================================
# Restart Services
# ============================================================================

restart_services() {
    log_info "Restarting affected applications..."

    # Restart Finder
    killall Finder

    # Restart Dock (if any dock settings were changed)
    killall Dock

    log_success "Services restarted"
}

# ============================================================================
# Main
# ============================================================================

main() {
    log_info "Running macOS-specific setup..."
    echo ""

    setup_xcode_tools
    install_fonts
    install_macos_apps
    if ! setup_colima_service; then
        log_warning "Colima service setup encountered issues; continuing with rest of macOS setup"
    fi

    echo ""
    read -p "Do you want to configure macOS system defaults? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_macos_defaults
        clean_finder_views
        restart_services
    else
        log_info "Skipping macOS defaults configuration"
    fi

    echo ""
    log_success "macOS-specific setup complete!"
    echo ""
    log_info "Recommended next steps:"
    echo "  1. Install additional apps from Setapp/App Store"
    echo "  2. Configure System Settings > Keyboard > Shortcuts"
    echo "  3. Review and customize macOS defaults in this script"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
