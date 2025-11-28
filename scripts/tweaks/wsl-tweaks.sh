#!/usr/bin/env bash
#
# WSL-specific setup script
# Run after main installation to configure WSL-specific settings
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions from parent directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

set_log_context "WSL"

# Ensure Docker uses XDG config
export DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker"

# ============================================================================
# Detect Windows Username
# ============================================================================

detect_windows_username() {
    # Try to get Windows username using cmd.exe
    local win_user
    if command -v cmd.exe &>/dev/null; then
        win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
        if [[ -n "$win_user" ]] && [[ -d "/mnt/c/Users/$win_user" ]]; then
            echo "$win_user"
            return 0
        fi
    fi

    # Fallback: try to find a writable user directory in /mnt/c/Users
    for user_dir in /mnt/c/Users/*/; do
        local username
        username=$(basename "$user_dir")
        # Skip system directories
        if [[ "$username" =~ ^(Public|Default|All Users|Default User)$ ]]; then
            continue
        fi
        # Check if directory is writable
        if [[ -w "$user_dir" ]]; then
            echo "$username"
            return 0
        fi
    done

    # Last resort: use WSL username
    echo "$USER"
}

# ============================================================================
# WSL Configuration
# ============================================================================

configure_wsl() {
    log_info "Configuring WSL settings..."

    # Create or update /etc/wsl.conf
    if [[ -f "/etc/wsl.conf" ]]; then
        log_info "/etc/wsl.conf already exists"
    else
        log_info "Creating /etc/wsl.conf..."
        sudo tee /etc/wsl.conf > /dev/null <<EOF
# WSL Configuration

[automount]
enabled = true
root = /mnt/
options = "metadata,umask=22,fmask=11"

[network]
generateHosts = true
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true

[user]
default = $USER
EOF
        log_success "/etc/wsl.conf created"
        log_warning "You may need to restart WSL: wsl --shutdown (run from Windows)"
    fi
}

# ============================================================================
# Windows Integration
# ============================================================================

setup_windows_integration() {
    log_info "Setting up Windows integration..."

    # Detect Windows username
    local WIN_USER
    WIN_USER=$(detect_windows_username)
    WIN_HOME="/mnt/c/Users/$WIN_USER"

    if [[ -d "$WIN_HOME" ]]; then
        log_info "Windows home directory found: $WIN_HOME"

        # Create symlinks to Windows directories
        local dirs=("Downloads" "Documents" "Desktop")

        for dir in "${dirs[@]}"; do
            if [[ -d "$WIN_HOME/$dir" ]] && [[ ! -L "$HOME/$dir" ]] && [[ ! -d "$HOME/$dir" ]]; then
                ln -s "$WIN_HOME/$dir" "$HOME/$dir"
                log_info "Linked ~/$dir -> $WIN_HOME/$dir"
            fi
        done

        log_success "Windows integration complete"
    else
        log_warning "Windows home directory not found at $WIN_HOME"
    fi
}

# ============================================================================
# Shell Configuration
# ============================================================================

configure_shell() {
    log_info "Configuring default shell..."

    # Check if zsh is installed
    if ! command -v zsh &>/dev/null; then
        log_warning "zsh is not installed. Please install it first."
        return 1
    fi

    # Get current shell
    local current_shell
    current_shell=$(basename "$SHELL")

    if [[ "$current_shell" != "zsh" ]]; then
        log_info "Current shell is $current_shell, switching to zsh..."
        
        # Ensure zsh is in /etc/shells
        if ! grep -q "$(which zsh)" /etc/shells; then
            log_info "Adding zsh to /etc/shells..."
            which zsh | sudo tee -a /etc/shells > /dev/null
        fi

        # Change default shell
        if chsh -s "$(which zsh)"; then
            log_success "Default shell changed to zsh"
            log_warning "Please log out and log back in for the change to take effect"
        else
            log_error "Failed to change default shell to zsh"
            return 1
        fi
    else
        log_info "Default shell is already zsh"
    fi
}

# ============================================================================
# WSL-specific Tools
# ============================================================================

install_wsl_tools() {
    log_info "Installing WSL-specific tools..."

    # Install wslu for WSL utilities
    if ! command -v wslview &>/dev/null; then
        log_info "Installing wslu (WSL utilities)..."
        sudo apt install -y wslu
    else
        log_info "wslu already installed"
    fi

    # Install GUI support dependencies (for X11 apps)
    log_info "Checking for GUI support packages..."

    read -p "Do you want to install GUI support (X11) packages? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt install -y \
            x11-apps \
            mesa-utils \
            libgl1
        log_success "GUI support packages installed"
    fi
}

# ============================================================================
# Docker Compose Plugin Setup
# ============================================================================

setup_docker_compose_plugin() {
    if ! command -v docker &>/dev/null; then
        log_info "Docker not installed, skipping docker compose plugin setup"
        return 0
    fi

    log_info "Setting up Docker Compose plugin (v2 with space support)..."

    # Check if docker compose (with space) already works
    if docker compose version &>/dev/null; then
        log_info "Docker Compose plugin already installed"
        docker compose version
        return 0
    fi

    log_info "Installing Docker Compose plugin..."

    # Create plugin directory
    local plugin_dir="${DOCKER_CONFIG:-$HOME/.config/docker}/cli-plugins"
    mkdir -p "$plugin_dir"

    # Detect architecture
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac

    # Get latest version
    log_info "Fetching latest Docker Compose version..."
    local version
    version=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$version" ]]; then
        log_error "Failed to fetch latest version"
        return 1
    fi

    log_info "Installing Docker Compose $version for $arch..."

    # Download and install
    local download_url="https://github.com/docker/compose/releases/download/${version}/docker-compose-linux-${arch}"

    if curl -fsSL "$download_url" -o "$plugin_dir/docker-compose"; then
        chmod +x "$plugin_dir/docker-compose"
        log_success "Docker Compose plugin installed successfully"

        # Verify installation
        if docker compose version &>/dev/null; then
            log_success "Docker Compose plugin is working correctly"
            docker compose version
        else
            log_warning "Docker Compose plugin installed but verification failed"
            return 1
        fi
    else
        log_error "Failed to download Docker Compose plugin"
        return 1
    fi
}

# ============================================================================
# Performance Tuning
# ============================================================================

configure_performance() {
    log_info "Configuring WSL performance settings..."

    # Detect Windows username and create .wslconfig in Windows home directory
    local WIN_USER
    WIN_USER=$(detect_windows_username)
    WIN_HOME="/mnt/c/Users/$WIN_USER"
    WSLCONFIG="$WIN_HOME/.wslconfig"

    if [[ ! -d "$WIN_HOME" ]]; then
        log_warning "Windows home directory not found at $WIN_HOME, skipping .wslconfig creation"
        return 0
    fi

    if [[ ! -f "$WSLCONFIG" ]]; then
        log_info "Creating .wslconfig for performance tuning..."

        # Detect system memory
        TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
        WSL_MEM=$(( TOTAL_MEM * 3 / 4 ))  # Use 75% of total memory

        cat > "$WSLCONFIG" <<EOF
# WSL 2 Global Configuration
# Located at: $WSLCONFIG

[wsl2]
# Memory allocation (GB) - using 75% of total
memory=${WSL_MEM}GB

# CPU cores (using all available cores)
processors=$(nproc)

# Swap size
swap=8GB

# Localhostforwarding
localhostForwarding=true

# Enable nested virtualization
nestedVirtualization=true
EOF
        log_success ".wslconfig created"
        log_warning "Restart WSL to apply: wsl --shutdown (from Windows)"
    else
        log_info ".wslconfig already exists at $WSLCONFIG"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    log_info "Running WSL-specific setup..."
    echo ""

    configure_wsl
    setup_windows_integration
    configure_shell
    install_wsl_tools
    if ! setup_docker_compose_plugin; then
        log_warning "Docker Compose plugin setup encountered issues; continuing with rest of WSL setup"
    fi
    configure_performance

    echo ""
    log_success "WSL-specific setup complete!"
    echo ""
    log_info "Recommended next steps:"
    echo "  1. Restart WSL: wsl --shutdown (run from Windows PowerShell)"
    echo "  2. Install Windows Terminal from Microsoft Store"
    echo "  3. Log out and log back in if shell was changed to zsh"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
