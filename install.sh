#!/usr/bin/env bash
#
# Dotfiles installer - symlinks configs with optional OS tweaks.
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
    defaults write com.apple.dock tilesize -int 32
    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock show-process-indicators -bool true
    defaults write com.apple.dock autohide -bool false
    defaults write com.apple.dock show-recents -bool false

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

    # Tips - completely disabled
    defaults write com.apple.tips TipsEnabled -bool false
    defaults write com.apple.tips CloudKitSyncingEnabled -bool false
    defaults write com.apple.tips NotificationsEnabled -bool false

    # Restart affected services
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    success "macOS defaults applied"

    # Xcode CLI tools
    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
    fi
}

set_locale_systemd() {
    if command -v localectl >/dev/null 2>&1; then
        sudo localectl set-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    else
        warn "localectl not found; writing /etc/locale.conf directly"
        {
            echo "LANG=en_US.UTF-8"
            echo "LC_ALL=en_US.UTF-8"
        } | sudo tee /etc/locale.conf >/dev/null
    fi
}

# Linux/WSL tweaks - locale and shell setup
apply_linux_tweaks() {
    local distro_id=""
    local distro_like=""
    local is_debian_like=""
    local is_fedora_like=""
    local is_arch_like=""

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        distro_id="${ID:-}"
        distro_like="${ID_LIKE:-}"
    fi

    if [[ "$distro_id" == "debian" || "$distro_id" == "ubuntu" || "$distro_like" == *"debian"* ]]; then
        is_debian_like=1
    elif [[ "$distro_id" == "fedora" || "$distro_like" == *"rhel"* || "$distro_like" == *"fedora"* ]]; then
        is_fedora_like=1
    elif [[ "$distro_id" == "arch" || "$distro_like" == *"arch"* ]]; then
        is_arch_like=1
    fi

    # Setup locale
    if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
        info "Locale en_US.UTF-8 already available"
    else
        info "Installing en_US.UTF-8 locale..."
        if [[ -n "$is_debian_like" ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update -qq
                sudo apt-get install -y locales
                sudo locale-gen en_US.UTF-8
                success "Locale en_US.UTF-8 generated"
            else
                warn "apt-get not found; skipping locale install"
            fi
        elif [[ -n "$is_fedora_like" ]]; then
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y glibc-langpack-en
                success "Locale en_US.UTF-8 installed"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y glibc-langpack-en
                success "Locale en_US.UTF-8 installed"
            else
                warn "dnf/yum not found; skipping locale install"
            fi
        elif [[ -n "$is_arch_like" ]]; then
            if [[ -f /etc/locale.gen ]]; then
                sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
                sudo locale-gen
                success "Locale en_US.UTF-8 generated"
            else
                warn "/etc/locale.gen not found; skipping locale generation"
            fi
        else
            warn "Unsupported Linux distro for locale setup; skipping"
        fi
    fi

    if [[ -n "$is_debian_like" ]]; then
        if command -v update-locale >/dev/null 2>&1; then
            sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
        else
            set_locale_systemd
        fi
    elif [[ -n "$is_fedora_like" || -n "$is_arch_like" ]]; then
        set_locale_systemd
    fi

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

# Symlink dotfiles using GNU Stow
apply_symlinks() {
    info "Creating symlinks with stow..."

    cd "$DOTFILES_DIR"

    # Remove .DS_Store files that interfere with stow
    find . -name ".DS_Store" -delete 2>/dev/null

    # Ensure ~/.config exists
    mkdir -p "$HOME/.config"

    # Stow home/ to ~ (for .zshenv and other root-level dotfiles)
    stow -t ~ home

    # Stow config/ to ~/.config
    stow -t ~/.config config

    success "Symlinks created"
}

main() {
    info "Dotfiles installer"
    detect_platform

    local apply_tweaks="n"
    if [[ -t 0 ]]; then
        read -rn1 -p $'\nApply OS tweaks? (y/N) ' apply_tweaks || true
        echo ""
    else
        info "Non-interactive shell; skipping OS tweaks"
    fi
    if [[ "$apply_tweaks" =~ ^[Yy]$ ]]; then
        case "$PLATFORM" in
            macos) apply_macos_tweaks ;;
            linux|wsl) apply_linux_tweaks ;;
            *) warn "No tweaks for platform: $PLATFORM" ;;
        esac
    fi

    apply_symlinks
    success "Done!"
}

main "$@"
