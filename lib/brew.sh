#!/usr/bin/env bash

# Homebrew installation and management

# shellcheck source=lib/platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log "Homebrew already installed"
        return 0
    fi

    log "Homebrew package manager needs to be installed"
    log ""
    log "Homebrew will be installed from: https://brew.sh"
    log "Installation script: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    log ""
    log "Note: This will download and execute the official Homebrew installation script."
    log "You can review the script at: https://github.com/Homebrew/install"
    log ""

    # Ask for confirmation
    read -p "Proceed with Homebrew installation? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Homebrew installation cancelled by user"
        error "Homebrew is required for package management"
        error "Please install manually from https://brew.sh"
        return 1
    fi

    log "Installing Homebrew..."

    local install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

    if is_macos; then
        # macOS installation
        if ! /bin/bash -c "$(curl -fsSL "$install_url")"; then
            error "Homebrew installation failed"
            return 1
        fi
    else
        # Linux/WSL installation
        if ! /bin/bash -c "$(curl -fsSL "$install_url")"; then
            error "Homebrew installation failed"
            return 1
        fi

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

        # Run brew doctor to verify installation
        log "Verifying Homebrew installation..."
        brew doctor || warn "Homebrew installation may have issues (run 'brew doctor' for details)"
    else
        error "Homebrew installation verification failed"
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