#!/usr/bin/env bash
#
# Linux-specific setup script
# Run after main installation to configure Linux-specific settings
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions from parent directory
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

set_log_context "Linux"

# Ensure Docker uses XDG config
export DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker"

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
# Main
# ============================================================================

main() {
    log_info "Running Linux-specific setup..."
    echo ""

    configure_shell
    if ! setup_docker_compose_plugin; then
        log_warning "Docker Compose plugin setup encountered issues; continuing with rest of Linux setup"
    fi

    echo ""
    log_success "Linux-specific setup complete!"
    echo ""
    log_info "Recommended next steps:"
    echo "  1. Log out and log back in if shell was changed to zsh"
    echo "  2. Run 'docker compose version' to verify Docker Compose plugin"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
