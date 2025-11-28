#!/usr/bin/env bash
#
# Installs Oh My Posh prompt theme engine.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"

# Installs Oh My Posh prompt theme engine if not already present
install_ohmyposh() {
    log_info "Ensuring Oh My Posh is installed..."

    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    if command_exists oh-my-posh; then
        log_info "Oh My Posh already installed"
        return
    fi

    log_info "Installing Oh My Posh via official installer..."
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s

    if command_exists oh-my-posh; then
        log_success "Oh My Posh installed successfully"
    else
        log_warning "Oh My Posh installation may have failed - check $XDG_BIN_HOME"
    fi
}
