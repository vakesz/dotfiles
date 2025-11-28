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

# Ensure Colima uses XDG config
export COLIMA_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/colima"

# Ensure Docker uses XDG config
export DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker"

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
# Docker Socket Symlink (for Colima compatibility)
# ============================================================================

setup_docker_socket_symlink() {
    if ! command -v docker &>/dev/null; then
        log_info "Docker not installed, skipping socket symlink setup"
        return 0
    fi

    log_info "Setting up Docker socket symlink for macOS..."

    local colima_socket="${COLIMA_HOME}/default/docker.sock"
    local docker_socket="/var/run/docker.sock"

    # Check if symlink already points to the correct location
    if [ -L "$docker_socket" ] && [ "$(readlink "$docker_socket")" = "$colima_socket" ]; then
        log_info "Docker socket symlink already configured correctly"
        return 0
    fi

    # Check if docker socket exists but isn't our symlink
    if [ -e "$docker_socket" ]; then
        log_warning "Docker socket exists at $docker_socket but not pointing to Colima"
        log_info "Manual intervention may be required. Remove existing socket if needed."
        return 1
    fi

    # Create /var/run directory if it doesn't exist (requires sudo)
    if [ ! -d "/var/run" ]; then
        log_info "Creating /var/run directory..."
        sudo mkdir -p /var/run
    fi

    # Wait for Colima socket to be available
    if [ ! -S "$colima_socket" ]; then
        log_warning "Colima socket not found at $colima_socket"
        log_info "Start Colima first with: colima start"
        return 1
    fi

    # Create symlink (requires sudo)
    log_info "Creating symlink: $docker_socket -> $colima_socket"
    sudo ln -sf "$colima_socket" "$docker_socket"

    if [ -L "$docker_socket" ]; then
        log_success "Docker socket symlink created successfully"
    else
        log_warning "Failed to create Docker socket symlink"
        return 1
    fi
}

# ============================================================================
# Docker Config Setup
# ============================================================================

setup_docker_config() {
    if ! command -v docker &>/dev/null; then
        log_info "Docker not installed, skipping config setup"
        return 0
    fi

    log_info "Setting up Docker configuration..."

    local docker_config_dir="${DOCKER_CONFIG:-$HOME/.config/docker}"
    local docker_config_file="$docker_config_dir/config.json"

    # Create config directory if it doesn't exist
    mkdir -p "$docker_config_dir"

    # Check if config file exists
    if [ -f "$docker_config_file" ]; then
        # Config exists, check if it already has cliPluginsExtraDirs
        if grep -q "cliPluginsExtraDirs" "$docker_config_file"; then
            log_info "Docker config already has cliPluginsExtraDirs configured"
            return 0
        fi

        log_info "Updating existing Docker config..."
        # Backup existing config
        cp "$docker_config_file" "$docker_config_file.backup"

        # Use jq to merge if available, otherwise manual merge
        if command -v jq &>/dev/null; then
            jq '. + {"cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]}' "$docker_config_file" > "$docker_config_file.tmp"
            mv "$docker_config_file.tmp" "$docker_config_file"
        else
            log_warning "jq not found, manually add cliPluginsExtraDirs to $docker_config_file"
            return 1
        fi
    else
        # Create new config file
        log_info "Creating new Docker config..."
        cat > "$docker_config_file" <<'EOF'
{
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
EOF
    fi

    log_success "Docker config configured"
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
    if ! setup_docker_config; then
        log_warning "Docker config setup encountered issues; continuing with rest of macOS setup"
    fi
    if ! setup_docker_socket_symlink; then
        log_warning "Docker socket symlink setup encountered issues; you may need to run 'colima start' first"
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
