#!/usr/bin/env bash
set -euo pipefail

# Dotfiles installer - cross-platform setup using Homebrew

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
# shellcheck source=lib/platform.sh
source "$REPO_DIR/lib/platform.sh"
# shellcheck source=lib/brew.sh
source "$REPO_DIR/lib/brew.sh"
# shellcheck source=lib/symlink.sh
source "$REPO_DIR/lib/symlink.sh"

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -u, --update        Update existing installation
    --skip-packages     Skip package installation
    --skip-symlinks     Skip symlinking dotfiles
    --cleanup           Clean up broken symlinks only

EXAMPLES:
    $0                  Full installation
    $0 --update         Update packages and refresh symlinks
    $0 --skip-packages  Only symlink dotfiles
EOF
}

check_requirements() {
    log "Checking system requirements..."

    local os
    os="$(detect_os)"

    log "Detected OS: $os"

    case "$os" in
        macos)
            # macOS should have curl by default
            if ! command -v curl >/dev/null 2>&1; then
                error "curl is required but not found"
                return 1
            fi
            ;;
        linux|wsl)
            # Linux systems need curl and basic tools
            if ! command -v curl >/dev/null 2>&1; then
                log "Installing curl and basic requirements..."
                if command -v apt-get >/dev/null 2>&1; then
                    sudo apt-get update && sudo apt-get install -y curl build-essential
                elif command -v yum >/dev/null 2>&1; then
                    sudo yum install -y curl gcc gcc-c++ make
                elif command -v dnf >/dev/null 2>&1; then
                    sudo dnf install -y curl gcc gcc-c++ make
                else
                    error "No supported package manager found"
                    return 1
                fi
            fi
            ;;
        *)
            error "Unsupported operating system: $os"
            return 1
            ;;
    esac

    success "System requirements satisfied"
}

setup_shell_environment() {
    log "Setting up shell environment..."

    # Ensure Homebrew is in PATH for current session
    setup_brew_environment

    # Set up shell-specific configurations
    local shell_name
    shell_name="$(basename "$SHELL")"

    case "$shell_name" in
        zsh)
            # Zsh will be configured via dotfiles
            log "Zsh detected - configuration will be handled by dotfiles"
            ;;
        bash)
            log "Bash detected - consider switching to zsh for better experience"
            ;;
        *)
            warn "Unknown shell: $shell_name"
            ;;
    esac
}

install_nodejs_with_nvm() {
    log "Installing nvm using official installer..."
    
    # Check if nvm is already installed
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        log "nvm is already installed, skipping installation"
    else
        # Install nvm using the official curl method
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        
        # Source nvm for the current session
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi

    # Uninstall existing Node.js from Homebrew to prevent conflicts
    if brew list --formula | grep -q "node"; then
        log "Removing conflicting Node.js installation from Homebrew..."
        brew uninstall node
    fi

    # Source nvm if not already loaded
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install the latest LTS version of Node.js
    log "Installing latest LTS Node.js version..."
    nvm install --lts
    nvm alias default 'lts/*'
    nvm use default
    
    success "nvm and Node.js LTS installed successfully"
}

post_install_setup() {
    log "Running post-installation setup..."

    # Platform-specific post-install tasks
    if is_linux || is_wsl; then
        # Install recommended fonts for Linux/WSL
        if command -v fc-cache >/dev/null 2>&1; then
            log "Refreshing font cache..."
            fc-cache -fv >/dev/null 2>&1 || true
        fi

        # WSL-specific setup
        if is_wsl; then
            log "Applying WSL-specific configurations..."

            # Set up locale if needed
            if ! locale -a 2>/dev/null | grep -q "en_US.utf8"; then
                if [[ -f /etc/locale.gen ]]; then
                    sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
                    sudo locale-gen >/dev/null 2>&1 || true
                fi
            fi
        fi
    fi

    # Set up development directories
    mkdir -p "$HOME/workspace" "$HOME/bin"

    success "Post-installation setup completed"
}

main() {
    local skip_packages=false
    local skip_symlinks=false
    local update_mode=false
    local cleanup_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -u|--update)
                update_mode=true
                shift
                ;;
            --skip-packages)
                skip_packages=true
                shift
                ;;
            --skip-symlinks)
                skip_symlinks=true
                shift
                ;;
            --cleanup)
                cleanup_only=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log "Starting dotfiles setup..."
    log "Repository: $REPO_DIR"

    # Cleanup mode - just remove broken symlinks
    if [[ "$cleanup_only" == true ]]; then
        cleanup_broken_links "$REPO_DIR/config"
        exit 0
    fi

    # Check system requirements
    check_requirements

    # Install or update Homebrew
    if [[ "$skip_packages" == false ]]; then
        install_homebrew
        setup_brew_environment

        if [[ "$update_mode" == true ]]; then
            update_homebrew
        fi

        # Install packages from Brewfile
        install_packages "$REPO_DIR/Brewfile"

        # Install Node.js using nvm
        install_nodejs_with_nvm
    fi

    # Set up shell environment
    setup_shell_environment

    # Symlink dotfiles
    if [[ "$skip_symlinks" == false ]]; then
        link_dotfiles "$REPO_DIR/config"
        cleanup_broken_links "$REPO_DIR/config"
    fi

    # Post-installation setup
    post_install_setup

    success "Dotfiles setup completed!"

    if [[ "$update_mode" == false ]]; then
        log ""
        log "Next steps:"
        log "1. Restart your shell or run: exec \$SHELL"
        log "2. For macOS: Install apps from Mac App Store if needed"
        log "3. Configure Git with your name and email if needed"
        log ""
        log "To update in the future, run: $0 --update"
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi