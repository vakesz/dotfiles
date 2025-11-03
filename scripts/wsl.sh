#!/usr/bin/env bash
#
# WSL-specific setup script
# Run after main installation to configure WSL-specific settings
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Override logging functions with WSL prefix
log_info() {
    echo -e "${BLUE}[WSL]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[WSL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WSL]${NC} $1"
}

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
        local username=$(basename "$user_dir")
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
    local WIN_USER=$(detect_windows_username)
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
# Performance Tuning
# ============================================================================

configure_performance() {
    log_info "Configuring WSL performance settings..."

    # Detect Windows username and create .wslconfig in Windows home directory
    local WIN_USER=$(detect_windows_username)
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
# Git Credential Manager
# ============================================================================

setup_git_credential_manager() {
    log_info "Setting up Git Credential Manager..."

    # Use Windows Git Credential Manager from WSL
    if command -v git &>/dev/null; then
        git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
        log_success "Git Credential Manager configured"
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
    install_wsl_tools
    configure_performance
    setup_git_credential_manager

    echo ""
    log_success "WSL-specific setup complete!"
    echo ""
    log_info "Recommended next steps:"
    echo "  1. Restart WSL: wsl --shutdown (run from Windows PowerShell)"
    echo "  2. Install Windows Terminal from Microsoft Store"
    echo "  3. Configure Windows Terminal to use WSL as default"
    echo "  4. Consider installing Docker Desktop for Windows with WSL 2 backend"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
