#!/usr/bin/env bash
#
# macOS-specific setup script
# Run after main installation to configure macOS-specific settings
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Override logging functions with macOS prefix
log_info() {
    echo -e "${BLUE}[macOS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[macOS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[macOS]${NC} $1"
}

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

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Safari: enable developer menu (may fail due to App Sandboxing)
    # Note: Safari's preferences are sandboxed and may require manual configuration
    defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || \
        log_warning "Could not configure Safari (requires manual setup in Safari > Settings > Advanced)"
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true 2>/dev/null || true

    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    # Dock: set icon size to 24px
    defaults write com.apple.dock tilesize -int 24

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

    # Move existing ~/.colima to XDG-compliant location
    if [[ -d "$HOME/.colima" ]] && [[ ! -d "$HOME/.config/colima" ]]; then
        log_info "Moving Colima config to XDG location..."
        mv "$HOME/.colima" "$HOME/.config/colima"
    fi

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

    # Start Colima with optimized settings
    log_info "Starting Colima with optimized settings..."
    colima start --cpu 2 --memory 4 --disk 60 --vm-type=vz --mount-type=virtiofs --dns 1.1.1.1 || {
        log_warning "Failed to start Colima with custom settings, trying defaults..."
        colima start
    }

    # Enable Colima as a service
    log_info "Enabling Colima as a macOS service..."
    brew services start colima

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
    setup_colima_service

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
