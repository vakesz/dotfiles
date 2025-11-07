#!/usr/bin/env bash
#
# Dotfiles installation script
# Supports macOS (brew), Linux (apt), and WSL
#

set -e

# Script directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Source common functions
source "$SCRIPTS_DIR/common.sh"

# Detect OS
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate packages.json
validate_packages_json() {
    local packages_json="$SCRIPTS_DIR/packages.json"

    if [[ ! -f "$packages_json" ]]; then
        log_error "packages.json not found"
        return 1
    fi

    if ! command_exists jq; then
        log_warning "jq not available, skipping JSON validation"
        return 0
    fi

    # Validate JSON syntax
    if ! jq empty "$packages_json" 2>/dev/null; then
        log_error "packages.json contains invalid JSON"
        return 1
    fi

    # Validate structure
    if ! jq -e '.packages | type == "object"' "$packages_json" >/dev/null 2>&1; then
        log_error "packages.json missing 'packages' object"
        return 1
    fi

    log_info "packages.json validated successfully"
    return 0
}

# Install Homebrew (macOS only)
install_homebrew() {
    if [[ "$OS" != "macos" ]]; then
        return
    fi

    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for current session
        eval "$(/opt/homebrew/bin/brew shellenv)"

        log_success "Homebrew installed"
    else
        log_info "Homebrew already installed"
    fi
}

# Update package manager
update_package_manager() {
    log_info "Skipping package manager updates (use 'topgrade' to update everything)"
    # Package updates are handled by topgrade, not during installation
    return 0
}

# Parse packages.json and extract package names for a specific package manager
get_packages_for_manager() {
    local manager="$1"
    local packages_json="$SCRIPTS_DIR/packages.json"

    if [[ ! -f "$packages_json" ]]; then
        log_warning "packages.json not found"
        return
    fi

    # Extract packages for the specified manager using jq
    if command_exists jq; then
        jq -r --arg mgr "$manager" '
            .packages
            | to_entries[]
            | .value[]
            | select(.[$mgr] != null and .[$mgr] != "")
            | .[$mgr]
        ' "$packages_json" | tr '\n' ' '
    fi
}

# Get packages that need manual installation
get_manual_packages() {
    local packages_json="$SCRIPTS_DIR/packages.json"

    if [[ ! -f "$packages_json" ]] || ! command_exists jq; then
        return
    fi

    jq -r '
        .packages
        | to_entries[]
        | .value[]
        | select(.manual != null)
        | "\(.name):\(.manual)"
    ' "$packages_json"
}

# Helper functions for package installation
install_brew_packages() {
    if ! command_exists brew; then
        return 0
    fi

    log_info "Installing packages via Homebrew from packages.json..."
    local brew_packages_str=$(get_packages_for_manager "brew")

    if [[ -n "$brew_packages_str" ]]; then
        # Convert to array for proper word splitting
        local -a brew_packages
        read -ra brew_packages <<< "$brew_packages_str"

        log_info "Installing: ${brew_packages[*]}"
        brew install "${brew_packages[@]}" || log_warning "Some packages failed to install"
        log_success "Homebrew packages installed"
    else
        log_warning "No packages found in packages.json"
    fi
}

install_apt_packages() {
    if ! command_exists apt; then
        return 0
    fi

    log_info "Installing packages via apt from packages.json..."
    local apt_packages_str=$(get_packages_for_manager "apt")

    if [[ -n "$apt_packages_str" ]]; then
        # Convert to array for proper word splitting
        local -a apt_packages
        read -ra apt_packages <<< "$apt_packages_str"

        log_info "Installing: ${apt_packages[*]}"
        sudo apt install -y "${apt_packages[@]}" || log_warning "Some packages failed to install"
        log_success "APT packages installed"
    fi
}

install_cargo_packages() {
    local cargo_packages=$(get_packages_for_manager "cargo")

    if [[ -z "$cargo_packages" ]]; then
        return 0
    fi

    # Install Rust if needed
    if ! command_exists cargo; then
        log_info "Installing Rust (needed for cargo packages)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"
    fi

    if command_exists cargo; then
        log_info "Installing cargo packages from packages.json..."
        log_info "Installing: $cargo_packages"
        for pkg in $cargo_packages; do
            cargo install "$pkg" 2>/dev/null || log_warning "Failed to install $pkg"
        done
        log_success "Cargo packages installed"
    fi
}

install_pip_packages() {
    local pip_packages=$(get_packages_for_manager "pip")

    if [[ -z "$pip_packages" ]]; then
        return 0
    fi

    if command_exists pipx; then
        log_info "Installing pip packages via pipx from packages.json..."
        log_info "Installing: $pip_packages"
        for pkg in $pip_packages; do
            pipx install "$pkg" 2>/dev/null || log_warning "Failed to install $pkg"
        done
        log_success "Pip packages installed via pipx"
    elif command_exists pip3; then
        log_info "Installing pip packages from packages.json..."
        # Convert to array for proper word splitting
        local -a pip_packages_array
        read -ra pip_packages_array <<< "$pip_packages"

        log_info "Installing: ${pip_packages_array[*]}"
        pip3 install --user "${pip_packages_array[@]}" 2>/dev/null || log_warning "Some pip packages failed to install (consider installing pipx)"
        log_success "Pip packages installed"
    fi
}

install_npm_packages() {
    if ! command_exists npm; then
        return 0
    fi

    local npm_packages_str=$(get_packages_for_manager "npm")

    if [[ -z "$npm_packages_str" ]]; then
        return 0
    fi

    # Convert to array for proper word splitting
    local -a npm_packages
    read -ra npm_packages <<< "$npm_packages_str"

    log_info "Installing npm packages from packages.json..."
    log_info "Installing: ${npm_packages[*]}"
    npm install -g "${npm_packages[@]}" || log_warning "Some npm packages failed to install"
    log_success "NPM packages installed"
}

install_manual_packages() {
    log_info "Checking for packages requiring manual installation..."
    while IFS=: read -r pkg_name install_cmd; do
        if [[ -n "$pkg_name" ]] && ! command_exists "$pkg_name"; then
            case "$pkg_name" in
                oh-my-posh)
                    log_info "Installing oh-my-posh..."
                    curl -s https://ohmyposh.dev/install.sh | bash -s || log_warning "Failed to install oh-my-posh"
                    ;;
                goimports)
                    if command_exists go; then
                        log_info "Installing goimports..."
                        go install golang.org/x/tools/cmd/goimports@latest || log_warning "Failed to install goimports"
                    else
                        log_warning "Go not installed, skipping goimports"
                    fi
                    ;;
                *)
                    log_info "Manual installation required for $pkg_name: $install_cmd"
                    ;;
            esac
        fi
    done < <(get_manual_packages)
}

# Install packages based on OS
install_packages() {
    if ! command_exists jq; then
        log_warning "jq not found, installing it first..."
        case "$OS" in
            macos)
                brew install jq
                ;;
            linux|wsl)
                sudo apt install -y jq
                ;;
        esac
    fi

    case "$OS" in
        macos)
            install_brew_packages
            ;;

        linux|wsl)
            install_apt_packages
            install_cargo_packages
            install_pip_packages
            install_npm_packages
            install_manual_packages
            ;;
    esac

    log_success "Package installation complete"
}

# Setup XDG directories
setup_xdg_directories() {
    log_info "Setting up XDG directories..."

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.local/state"
    mkdir -p "$HOME/.cache"

    # Create zsh-specific directories
    mkdir -p "$HOME/.local/state/zsh"
    mkdir -p "$HOME/.cache/zsh"

    # Create directories for XDG-compliant tools
    mkdir -p "$HOME/.local/state/less"
    mkdir -p "$HOME/.cache/python"

    log_success "XDG directories created"
}

# Backup existing dotfiles
backup_existing_files() {
    log_info "Backing up existing dotfiles..."

    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
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
            log_info "Backed up: $file"
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

# Setup dotfiles with stow
setup_stow() {
    log_info "Setting up dotfiles with stow..."

    cd "$DOTFILES_DIR"

    # Stow the main dotfiles
    if command_exists stow; then
        # Remove existing symlinks first
        stow -D . 2>/dev/null || true

        # Create new symlinks
        stow -v --adopt .

        log_success "Dotfiles symlinked with stow"
    else
        log_error "Stow not installed. Cannot setup dotfiles."
        return 1
    fi
}

# Setup Zsh as default shell
setup_zsh() {
    if ! command_exists zsh; then
        log_warning "Zsh not installed"
        return
    fi

    local zsh_path=$(which zsh)

    # Check if zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells; then
        log_info "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != "$zsh_path" ]]; then
        log_info "Changing default shell to zsh..."
        chsh -s "$zsh_path"
        log_success "Default shell changed to zsh (restart terminal to apply)"
    else
        log_info "Zsh is already the default shell"
    fi
}

# Run platform-specific setup
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

# Main installation flow
main() {
    log_info "Starting dotfiles installation..."
    echo ""

    detect_os

    if [[ "$OS" == "unknown" ]]; then
        log_error "Unsupported operating system"
        exit 1
    fi

    echo ""
    log_info "This script will:"
    echo "  1. Install/update package manager"
    echo "  2. Install essential packages"
    echo "  3. Setup XDG directories"
    echo "  4. Backup existing dotfiles"
    echo "  5. Symlink dotfiles using stow"
    echo "  6. Setup zsh as default shell"
    echo "  7. Run platform-specific setup"
    echo ""

    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi

    echo ""

    # Validate packages.json before proceeding
    if ! validate_packages_json; then
        log_error "Package configuration validation failed"
        exit 1
    fi

    # Installation steps
    if [[ "$OS" == "macos" ]]; then
        install_homebrew
    fi

    update_package_manager
    install_packages
    setup_xdg_directories
    backup_existing_files
    setup_stow
    setup_zsh
    run_platform_setup

    echo ""
    log_success "Dotfiles installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Your git config is already set via stow (.gitconfig)"

    if [[ "$OS" == "macos" ]]; then
        echo "  3. Review installed packages: brew list"
        echo "  4. Update everything: topgrade"
    fi

    if [[ "$OS" == "linux" ]] || [[ "$OS" == "wsl" ]]; then
        echo "  3. Verify PATH includes:"
        echo "     - \$HOME/.cargo/bin (Rust)"
        echo "     - \$HOME/.local/bin (local tools)"
        echo "  4. Update everything: topgrade"
    fi

    echo ""
    log_info "Note: Package managers may install additional dependencies"
    echo "  (e.g., Homebrew's 'rust' requires python@3.14 for build scripts)"
}

# Run main function
main "$@"
