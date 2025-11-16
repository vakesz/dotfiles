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

# Ensure XDG-compliant env vars are set for the session so installs use the same dirs
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Unset NPM_CONFIG_PREFIX if it exists (incompatible with NVM)
unset NPM_CONFIG_PREFIX 2>/dev/null || true

# Go (XDG)
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
export GOBIN="${GOBIN:-$GOPATH/bin}"
export PATH="$GOBIN:$PATH"

# Node/npm/pnpm (XDG)
# NVM is incompatible with NPM_CONFIG_PREFIX, so we don't set it
export NVM_DIR="${NVM_DIR:-${XDG_DATA_HOME}/nvm}"
export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME}/pnpm}"
export PATH="$PNPM_HOME:$PATH"

# Deno XDG
export DENO_INSTALL="${DENO_INSTALL:-${XDG_DATA_HOME}/deno}"
export PATH="$DENO_INSTALL/bin:$PATH"

# Rust/Cargo (XDG)
export CARGO_HOME="${CARGO_HOME:-${XDG_DATA_HOME}/cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-${XDG_DATA_HOME}/rustup}"
export PATH="$CARGO_HOME/bin:$PATH"

# pipx
export PIPX_HOME="${PIPX_HOME:-${XDG_DATA_HOME}/pipx}"
export PATH="$PIPX_HOME/venvs/bin:$PATH"


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

# Get list of toolchain package names for filtering
get_toolchain_packages() {
    local manager="$1"
    local packages_json="$SCRIPTS_DIR/packages.json"

    if [[ ! -f "$packages_json" ]] || ! command_exists jq; then
        return
    fi

    jq -r --arg mgr "$manager" '
        .packages.toolchains[]
        | select(.[$mgr] != null and .[$mgr] != "")
        | .[$mgr]
    ' "$packages_json" | tr '\n' ' '
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

## Legacy per-tool installers removed in favor of dynamic toolchain installer
## TODO: Re-run installs via `install_toolchains_dynamic` for any missing tools

install_toolchains() {
    log_info "=== PHASE 2: Installing Toolchains ==="
    echo ""

    # Ensure toolchain directories exist before installation
    mkdir -p "$NVM_DIR" "$CARGO_HOME" "$RUSTUP_HOME" "$GOPATH" "$DENO_INSTALL" 2>/dev/null || true

    # Installers are driven by scripts/packages.json to prefer first-party
    # toolchain installation where possible (install_script -> brew -> apt).
    install_toolchains_dynamic

    echo ""
}

install_toolchains_dynamic() {
    local packages_json="$SCRIPTS_DIR/packages.json"
    if [[ ! -f "$packages_json" ]] || ! command_exists jq; then
        log_warning "packages.json not found or jq missing, skipping dynamic toolchain installs"
        return 0
    fi

    # Read toolchains from JSON, sorted by install_order
    local toolchains_json
    toolchains_json=$(jq -r '.packages.toolchains | sort_by(.install_order) | .[] | @json' "$packages_json")

    if [[ -z "$toolchains_json" ]]; then
        log_warning "No toolchains found in packages.json"
        return 0
    fi

    log_info "Installing toolchains from packages.json (dynamically ordered)"

    while IFS= read -r toolchain; do
        local name install_script brew_pkg apt_pkg check_binary

        name=$(echo "$toolchain" | jq -r '.name')
        check_binary=$(echo "$toolchain" | jq -r '.check_binary // .name')
        install_script=$(echo "$toolchain" | jq -r '.install_script // empty')
        brew_pkg=$(echo "$toolchain" | jq -r '.brew // empty')
        apt_pkg=$(echo "$toolchain" | jq -r '.apt // empty')

        if command_exists "$check_binary"; then
            log_info "$name already available (binary: $check_binary), skipping"
            continue
        fi

        if [[ -n "$install_script" ]]; then
            log_info "Installing $name via install_script"

            # Special handling for rust: reload cargo environment after installation
            if [[ "$name" == "rust" ]]; then
                bash -lc "$install_script" || log_warning "install_script for $name failed"

                # Reload cargo environment if it was just installed
                if [[ -s "$CARGO_HOME/env" ]]; then
                    # shellcheck disable=SC1090
                    source "$CARGO_HOME/env"
                fi
            # Special handling for node: reload NVM after installation
            elif [[ "$name" == "node" ]]; then
                bash -lc "$install_script" || log_warning "install_script for $name failed"

                # Reload NVM if it was just installed
                if [[ -s "$NVM_DIR/nvm.sh" ]]; then
                    # shellcheck disable=SC1090
                    source "$NVM_DIR/nvm.sh"
                    # Install and use LTS version
                    if command_exists nvm; then
                        nvm install --lts
                        nvm use --lts
                    fi
                fi
            # Special handling for pnpm: ensure node/nvm is loaded
            elif [[ "$name" == "pnpm" ]]; then
                if [[ -n "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
                    # shellcheck disable=SC1090
                    source "$NVM_DIR/nvm.sh"
                    if command_exists nvm; then
                        nvm use --lts || true
                    fi
                fi
                bash -lc "$install_script" || log_warning "install_script for $name failed"
            else
                bash -lc "$install_script" || log_warning "install_script for $name failed"
            fi
        else
            case "$OS" in
                macos)
                    if [[ -n "$brew_pkg" ]]; then
                        local -a brew_args
                        read -ra brew_args <<< "$brew_pkg"
                        log_info "Installing $name via Homebrew: ${brew_args[*]}"
                        brew install "${brew_args[@]}" || log_warning "brew install $brew_pkg failed"
                    else
                        log_warning "No brew mapping for $name"
                    fi
                    ;;
                linux|wsl)
                    if [[ -n "$apt_pkg" ]]; then
                        local -a apt_args
                        read -ra apt_args <<< "$apt_pkg"
                        log_info "Installing $name via APT: ${apt_args[*]}"
                        sudo apt install -y "${apt_args[@]}" || log_warning "apt install $apt_pkg failed"
                    else
                        log_warning "No apt mapping for $name"
                    fi
                    ;;
            esac
        fi

        if command_exists "$check_binary"; then
            log_success "$name installed (binary: $check_binary)"
        else
            log_warning "$name may not be installed after installer; binary $check_binary not found"
        fi
    done <<< "$toolchains_json"
}

# ============================================================================
# PHASE 3: PACKAGES
# ============================================================================

install_packages_brew() {
    if ! command_exists brew; then
        return 0
    fi

    log_info "Installing packages via Homebrew..."

    local brew_packages_str
    brew_packages_str=$(get_packages "brew")
    if [[ -z "$brew_packages_str" ]]; then
        log_warning "No brew packages found"
        return 0
    fi

    # Get toolchain packages to skip (already installed in phase 2)
    local toolchain_packages_str
    toolchain_packages_str=$(get_toolchain_packages "brew")

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
            # Skip toolchains (already installed in phase 2)
            if [[ " $toolchain_packages_str " =~ \ $pkg\  ]]; then
                continue
            fi
            regular_packages+=("$pkg")
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

    local apt_packages_str
    apt_packages_str=$(get_packages "apt")
    if [[ -z "$apt_packages_str" ]]; then
        log_warning "No apt packages found"
        return 0
    fi

    local -a apt_packages
    read -ra apt_packages <<< "$apt_packages_str"

    # Get toolchain packages to skip (already installed in phase 2)
    local toolchain_packages_str
    toolchain_packages_str=$(get_toolchain_packages "apt")

    # Filter out already installed toolchains and Docker if already present
    local -a filtered_packages=()
    for pkg in "${apt_packages[@]}"; do
        # Skip toolchains (already installed in phase 2)
        if [[ " $toolchain_packages_str " =~ \ $pkg\  ]]; then
            continue
        fi

        # Skip Docker packages if docker is already installed (from Docker's official repo)
        case "$pkg" in
            docker.io|docker-compose-plugin)
                if command_exists docker; then
                    log_info "  Skipping $pkg (Docker already installed)"
                    continue
                fi
                ;;
        esac

        filtered_packages+=("$pkg")
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

    local cargo_packages
    cargo_packages=$(get_packages "cargo")
    local -a cargo_packages_arr
    read -ra cargo_packages_arr <<< "$cargo_packages"
    if [[ -z "$cargo_packages" ]]; then
        return 0
    fi

    log_info "Installing Cargo packages..."
    log_info "  Packages: $cargo_packages"

    for pkg in "${cargo_packages_arr[@]}"; do
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

    local npm_packages_str
    npm_packages_str=$(get_packages "npm")
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
    local pip_packages
    pip_packages=$(get_packages "pip")
    local -a pip_packages_arr
    read -ra pip_packages_arr <<< "$pip_packages"
    if [[ -z "$pip_packages" ]]; then
        return 0
    fi

    log_info "Installing Python packages..."
    log_info "  Packages: $pip_packages"

    if command_exists pipx; then
        for pkg in "${pip_packages_arr[@]}"; do
            pipx install "$pkg" || log_warning "Failed to install $pkg"
        done
    elif command_exists pip3; then
        pip3 install --user "${pip_packages_arr[@]}" || log_warning "Some pip packages failed"
    else
        log_warning "Neither pipx nor pip3 available"
        return 0
    fi

    log_success "Python packages installed"
}

install_packages_via_script() {
    local packages_json="$SCRIPTS_DIR/packages.json"
    if [[ ! -f "$packages_json" ]] || ! command_exists jq; then
        return 0
    fi

    log_info "Installing packages via install_script..."

    # Get all non-toolchain packages with install_script
    local packages_with_scripts
    packages_with_scripts=$(jq -r '
        .packages
        | to_entries[]
        | select(.key != "toolchains")
        | .value[]
        | select(.install_script != null and .install_script != "")
        | @json
    ' "$packages_json")

    if [[ -z "$packages_with_scripts" ]]; then
        log_info "No packages with install_script found"
        return 0
    fi

    while IFS= read -r package; do
        local name install_script check_binary

        name=$(echo "$package" | jq -r '.name')
        install_script=$(echo "$package" | jq -r '.install_script')
        check_binary=$(echo "$package" | jq -r '.check_binary // .name')

        # Skip if already installed
        if command_exists "$check_binary"; then
            log_info "  $name already installed (binary: $check_binary), skipping"
            continue
        fi

        log_info "  Installing $name via install_script..."
        bash -lc "$install_script" || log_warning "Failed to install $name"

        if command_exists "$check_binary"; then
            log_success "  $name installed (binary: $check_binary)"
        else
            log_warning "  $name may not be installed; binary $check_binary not found"
        fi
    done <<< "$packages_with_scripts"

    log_success "Packages via install_script completed"
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
    install_packages_via_script

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
