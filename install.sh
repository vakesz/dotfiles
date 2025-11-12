#!/usr/bin/env bash
#
# Dotfiles installation script - Simplified and maintainable
# Supports macOS (brew), Linux (apt), and WSL
#
# Installation Phases:
#   1. Primary package manager (brew/apt)
#   2. Toolchains (rust, node, go, python)
#   3. Packages via each manager
#   4. System configuration
#

set -e

# Script directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Source common functions
source "$SCRIPTS_DIR/common.sh"

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS="wsl"
        else
            OS="linux"
        fi
    else
        OS="unknown"
    fi

    log_info "Detected OS: $OS"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# JSON PARSING HELPERS
# ============================================================================

# Get packages for a specific package manager
get_packages() {
    local manager="$1"
    local packages_json="$SCRIPTS_DIR/packages.json"

    if [[ ! -f "$packages_json" ]] || ! command_exists jq; then
        return
    fi

    jq -r --arg mgr "$manager" '
        .packages
        | to_entries[]
        | .value[]
        | select(.[$mgr] != null and .[$mgr] != "")
        | .[$mgr]
    ' "$packages_json" | tr '\n' ' '
}

# Get toolchain info (name and install method)
get_toolchains() {
    local packages_json="$SCRIPTS_DIR/packages.json"

    if [[ ! -f "$packages_json" ]] || ! command_exists jq; then
        return
    fi

    jq -r '
        .packages.toolchains[]
        | "\(.name)|\(.brew // "")|\(.apt // "")|\(.install_script // "")"
    ' "$packages_json"
}

# ============================================================================
# PHASE 1: PRIMARY PACKAGE MANAGER
# ============================================================================

install_primary_manager() {
    log_info "=== PHASE 1: Installing Primary Package Manager ==="
    echo ""

    case "$OS" in
        macos)
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/opt/homebrew/bin/brew shellenv)"
                log_success "Homebrew installed"
            else
                log_info "Homebrew already installed"
            fi
            ;;
        linux|wsl)
            log_info "Using system apt package manager"
            sudo apt update
            ;;
    esac

    echo ""
}

# ============================================================================
# PHASE 2: TOOLCHAINS (PACKAGE MANAGERS)
# ============================================================================

install_toolchain_rust() {
    if command_exists cargo; then
        log_info "Rust/Cargo already installed"
        return 0
    fi

    log_info "Installing Rust toolchain via rustup..."

    # Set XDG-compliant paths
    export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
    export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
    export PATH="$CARGO_HOME/bin:$PATH"

    # Use rustup on all platforms for consistent toolchain management
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Source cargo env
    [[ -f "$CARGO_HOME/env" ]] && source "$CARGO_HOME/env"

    if command_exists cargo; then
        log_success "Rust/Cargo installed via rustup"
    else
        log_warning "Failed to install Rust"
    fi
}

install_toolchain_node() {
    if command_exists node && command_exists npm; then
        log_info "Node.js/NPM already installed"
        return 0
    fi

    log_info "Installing Node.js toolchain via nvm..."

    # Set XDG-compliant path
    export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"

    # Use nvm on all platforms for consistent version management
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    # Source nvm
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    # Install LTS version
    if command_exists nvm; then
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
    fi

    if command_exists node; then
        log_success "Node.js/NPM installed via nvm"
    else
        log_warning "Failed to install Node.js"
    fi
}

install_toolchain_go() {
    if command_exists go; then
        log_info "Go already installed"
        return 0
    fi

    log_info "Installing Go toolchain..."

    case "$OS" in
        macos)
            brew install go
            ;;
        linux|wsl)
            sudo apt install -y golang-go
            ;;
    esac

    if command_exists go; then
        log_success "Go installed"
    else
        log_warning "Failed to install Go"
    fi
}

install_toolchain_python() {
    if command_exists python3 && command_exists pip3; then
        log_info "Python already installed"

        # Ensure pipx is installed
        if ! command_exists pipx; then
            log_info "Installing pipx..."
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        fi
        return 0
    fi

    log_info "Installing Python toolchain..."

    case "$OS" in
        macos)
            brew install python@3.13
            brew install pipx || python3 -m pip install --user pipx
            ;;
        linux|wsl)
            sudo apt install -y python3 python3-pip pipx
            ;;
    esac

    if command_exists python3; then
        log_success "Python installed"
    else
        log_warning "Failed to install Python"
    fi
}

install_toolchains() {
    log_info "=== PHASE 2: Installing Toolchains ==="
    echo ""

    # Install in dependency order
    install_toolchain_rust
    install_toolchain_node
    install_toolchain_go
    install_toolchain_python

    echo ""
}

# ============================================================================
# PHASE 3: PACKAGES
# ============================================================================

install_packages_brew() {
    if ! command_exists brew; then
        return 0
    fi

    log_info "Installing packages via Homebrew..."

    local brew_packages_str=$(get_packages "brew")
    if [[ -z "$brew_packages_str" ]]; then
        log_warning "No brew packages found"
        return 0
    fi

    # Separate regular packages from cask packages
    local -a regular_packages=()
    local -a cask_packages=()
    local is_cask=false

    for pkg in $brew_packages_str; do
        if [[ "$pkg" == "--cask" ]]; then
            is_cask=true
        elif [[ "$is_cask" == true ]]; then
            cask_packages+=("$pkg")
            is_cask=false
        else
            # Skip toolchains (already installed)
            case "$pkg" in
                rust|node@*|go|python@*)
                    continue
                    ;;
                *)
                    regular_packages+=("$pkg")
                    ;;
            esac
        fi
    done

    # Install regular packages
    if [[ ${#regular_packages[@]} -gt 0 ]]; then
        log_info "  Regular: ${regular_packages[*]}"
        brew install "${regular_packages[@]}" || log_warning "Some packages failed"
    fi

    # Install cask packages
    if [[ ${#cask_packages[@]} -gt 0 ]]; then
        log_info "  Casks: ${cask_packages[*]}"
        brew install --cask "${cask_packages[@]}" || log_warning "Some casks failed"
    fi

    log_success "Homebrew packages installed"
}

install_packages_apt() {
    if ! command_exists apt; then
        return 0
    fi

    log_info "Installing packages via APT..."

    local apt_packages_str=$(get_packages "apt")
    if [[ -z "$apt_packages_str" ]]; then
        log_warning "No apt packages found"
        return 0
    fi

    local -a apt_packages
    read -ra apt_packages <<< "$apt_packages_str"

    # Filter out already installed toolchains
    local -a filtered_packages=()
    for pkg in "${apt_packages[@]}"; do
        case "$pkg" in
            golang-go|python3|python3-pip|pipx|nodejs|npm)
                # Skip if already installed in toolchain phase
                continue
                ;;
            *)
                filtered_packages+=("$pkg")
                ;;
        esac
    done

    if [[ ${#filtered_packages[@]} -gt 0 ]]; then
        log_info "  Packages: ${filtered_packages[*]}"
        sudo apt install -y "${filtered_packages[@]}" || log_warning "Some packages failed"
    fi

    log_success "APT packages installed"
}

install_packages_cargo() {
    if ! command_exists cargo; then
        log_warning "Cargo not available, skipping cargo packages"
        return 0
    fi

    local cargo_packages=$(get_packages "cargo")
    if [[ -z "$cargo_packages" ]]; then
        return 0
    fi

    log_info "Installing Cargo packages..."
    log_info "  Packages: $cargo_packages"

    for pkg in $cargo_packages; do
        # Skip if already installed via brew
        if command_exists "$pkg"; then
            log_info "  $pkg (already installed, skipping)"
            continue
        fi

        log_info "  Installing $pkg..."
        cargo install "$pkg" || log_warning "Failed to install $pkg"
    done

    log_success "Cargo packages installed"
}

install_packages_npm() {
    if ! command_exists npm; then
        log_warning "NPM not available, skipping npm packages"
        return 0
    fi

    local npm_packages_str=$(get_packages "npm")
    if [[ -z "$npm_packages_str" ]]; then
        return 0
    fi

    local -a npm_packages
    read -ra npm_packages <<< "$npm_packages_str"

    log_info "Installing NPM packages..."
    log_info "  Packages: ${npm_packages[*]}"

    npm install -g "${npm_packages[@]}" || log_warning "Some npm packages failed"

    log_success "NPM packages installed"
}

install_packages_pip() {
    local pip_packages=$(get_packages "pip")
    if [[ -z "$pip_packages" ]]; then
        return 0
    fi

    log_info "Installing Python packages..."
    log_info "  Packages: $pip_packages"

    if command_exists pipx; then
        for pkg in $pip_packages; do
            pipx install "$pkg" || log_warning "Failed to install $pkg"
        done
    elif command_exists pip3; then
        pip3 install --user $pip_packages || log_warning "Some pip packages failed"
    else
        log_warning "Neither pipx nor pip3 available"
        return 0
    fi

    log_success "Python packages installed"
}

install_packages_go() {
    if ! command_exists go; then
        return 0
    fi

    log_info "Installing Go packages..."

    # Install goimports if go is available
    if ! command_exists goimports; then
        log_info "  Installing goimports..."
        go install golang.org/x/tools/cmd/goimports@latest
    fi

    log_success "Go packages installed"
}

install_packages_custom() {
    log_info "Installing custom packages..."

    # oh-my-posh (if not installed via brew)
    if ! command_exists oh-my-posh; then
        log_info "  Installing oh-my-posh..."
        curl -s https://ohmyposh.dev/install.sh | bash -s || log_warning "Failed to install oh-my-posh"
    fi

    log_success "Custom packages installed"
}

install_all_packages() {
    log_info "=== PHASE 3: Installing Packages ==="
    echo ""

    case "$OS" in
        macos)
            install_packages_brew
            ;;
        linux|wsl)
            install_packages_apt
            ;;
    esac

    install_packages_cargo
    install_packages_npm
    install_packages_pip
    install_packages_go
    install_packages_custom

    echo ""
}

# ============================================================================
# PHASE 4: SYSTEM CONFIGURATION
# ============================================================================

setup_xdg_directories() {
    log_info "Setting up XDG directories..."

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.local/state"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.local/state/zsh"
    mkdir -p "$HOME/.cache/zsh"
    mkdir -p "$HOME/.local/state/less"
    mkdir -p "$HOME/.cache/python"

    log_success "XDG directories created"
}

backup_existing_files() {
    log_info "Backing up existing dotfiles..."

    local backup_dir
    backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local files_to_backup=(
        ".zshenv"
        ".zshrc"
        ".gitconfig"
        ".config/nvim"
        ".config/tmux"
        ".config/zsh"
    )

    local backed_up=0
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
            mkdir -p "$backup_dir/$(dirname "$file")"
            mv "$HOME/$file" "$backup_dir/$file"
            log_info "  Backed up: $file"
            backed_up=1
        fi
    done

    if [[ $backed_up -eq 1 ]]; then
        log_success "Backup created at: $backup_dir"
    else
        log_info "No files to backup"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

setup_stow() {
    log_info "Setting up dotfiles with stow..."

    cd "$DOTFILES_DIR"

    if command_exists stow; then
        stow -D . 2>/dev/null || true
        stow -v --adopt .
        log_success "Dotfiles symlinked"
    else
        log_error "Stow not installed"
        return 1
    fi
}

setup_zsh() {
    if ! command_exists zsh; then
        log_warning "Zsh not installed"
        return
    fi

    local zsh_path
    zsh_path=$(which zsh)

    if ! grep -q "$zsh_path" /etc/shells; then
        log_info "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        log_info "Changing default shell to zsh..."
        chsh -s "$zsh_path"
        log_success "Default shell changed (restart terminal)"
    else
        log_info "Zsh already default shell"
    fi
}

run_platform_setup() {
    case "$OS" in
        macos)
            if [[ -f "$SCRIPTS_DIR/mac.sh" ]]; then
                log_info "Running macOS-specific setup..."
                bash "$SCRIPTS_DIR/mac.sh"
            fi
            ;;
        wsl)
            if [[ -f "$SCRIPTS_DIR/wsl.sh" ]]; then
                log_info "Running WSL-specific setup..."
                bash "$SCRIPTS_DIR/wsl.sh"
            fi
            ;;
    esac
}

configure_system() {
    log_info "=== PHASE 4: System Configuration ==="
    echo ""

    setup_xdg_directories
    backup_existing_files
    setup_stow
    setup_zsh
    run_platform_setup

    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Starting dotfiles installation..."
    echo ""

    detect_os

    if [[ "$OS" == "unknown" ]]; then
        log_error "Unsupported operating system"
        exit 1
    fi

    echo ""
    log_info "Installation Phases:"
    echo "  1. Primary package manager (brew/apt)"
    echo "  2. Toolchains (rust, node, go, python)"
    echo "  3. Packages via each manager"
    echo "  4. System configuration"
    echo ""

    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi

    echo ""

    # Validate packages.json
    if ! jq empty "$SCRIPTS_DIR/packages.json" 2>/dev/null; then
        log_error "Invalid packages.json"
        exit 1
    fi

    # Run installation phases
    install_primary_manager
    install_toolchains
    install_all_packages
    configure_system

    echo ""
    log_success "Dotfiles installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Update everything: topgrade"
    echo ""
}

# Run main
main "$@"
