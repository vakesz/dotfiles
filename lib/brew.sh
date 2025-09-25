#!/usr/bin/env bash

# Homebrew installation and management

# shellcheck source=lib/platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log "Homebrew already installed"
        return 0
    fi

    log "Installing Homebrew..."

    if is_macos; then
        # macOS installation
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        # Linux/WSL installation
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Linux/WSL
        if [[ -d /home/linuxbrew/.linuxbrew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -d ~/.linuxbrew ]]; then
            eval "$(~/.linuxbrew/bin/brew shellenv)"
        fi
    fi

    # Verify installation
    if command -v brew >/dev/null 2>&1; then
        success "Homebrew installed successfully"
    else
        error "Homebrew installation failed"
        return 1
    fi
}

setup_brew_environment() {
    # Ensure brew is in PATH
    if is_macos; then
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        if [[ -d /home/linuxbrew/.linuxbrew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -d ~/.linuxbrew ]]; then
            eval "$(~/.linuxbrew/bin/brew shellenv)"
        fi
    fi
}

install_packages() {
    local brewfile="$1"

    if [[ ! -f "$brewfile" ]]; then
        error "Brewfile not found: $brewfile"
        return 1
    fi

    log "Installing packages from Brewfile..."

    setup_brew_environment

    if brew bundle --file="$brewfile"; then
        success "All packages installed successfully"
    else
        warn "Some packages may have failed to install"
        return 1
    fi
}

update_homebrew() {
    log "Updating Homebrew..."
    setup_brew_environment

    brew update
    brew upgrade
    brew cleanup

    success "Homebrew updated"
}