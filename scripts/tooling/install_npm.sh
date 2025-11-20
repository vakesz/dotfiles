#!/usr/bin/env bash
#
# Installs Node via nvm, enables pnpm, and installs curated npm tools.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"

setup_node_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export NVM_DIR="${NVM_DIR:-${XDG_DATA_HOME}/nvm}"
    export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME}/pnpm}"

    # Ensure directories exist
    mkdir -p "$NVM_DIR" "$PNPM_HOME"

    export PATH="$PNPM_HOME:$PATH"
}

install_npm_tooling() {
    log_info "Setting up Node/npm tooling..."

    setup_node_env

    # Verify NVM_DIR is set and accessible
    if [[ -z "${NVM_DIR:-}" ]]; then
        log_error "NVM_DIR is not set; cannot install Node"
        return 1
    fi

    if [[ ! -d "$NVM_DIR" ]]; then
        log_error "NVM_DIR directory does not exist: $NVM_DIR"
        return 1
    fi

    # Source nvm if already installed
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck disable=SC1090,SC1091
        source "$NVM_DIR/nvm.sh"
    fi

    # Install nvm if not available
    if ! command_exists nvm; then
        log_info "nvm not installed, fetching installer..."
        if ! curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; then
            log_warning "nvm installation failed (network issue?)"
            return 1
        fi

        # Source nvm after installation
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            # shellcheck disable=SC1090,SC1091
            source "$NVM_DIR/nvm.sh"
        else
            log_error "nvm.sh not found after installation at $NVM_DIR/nvm.sh"
            return 1
        fi
    fi

    # Verify nvm command is now available
    if ! command_exists nvm; then
        log_error "nvm command not available after installation; check $NVM_DIR/nvm.sh"
        return 1
    fi

    # Install Node via nvm even if system node exists
    # This ensures we have nvm-managed node for version switching
    if ! nvm list 2>/dev/null | grep -q "v[0-9]"; then
        log_info "Installing Node LTS via nvm..."
        if ! nvm install --lts; then
            log_warning "nvm install --lts failed (network issue?)"
            return 1
        fi
    else
        log_info "Node already installed via nvm"
    fi

    # Find the latest installed Node version directly from filesystem
    # This avoids calling nvm commands which can hang in some contexts
    local latest_node_dir
    latest_node_dir=$(find "$NVM_DIR/versions/node" -maxdepth 1 -type d -name "v*" 2>/dev/null | sort -V | tail -n1)

    if [[ -z "$latest_node_dir" ]] || [[ ! -d "$latest_node_dir" ]]; then
        log_error "No Node versions found in $NVM_DIR/versions/node"
        return 1
    fi

    local nvm_bin="$latest_node_dir/bin"

    if [[ ! -d "$nvm_bin" ]]; then
        log_error "Node bin directory not found at $nvm_bin"
        return 1
    fi

    # Prepend nvm bin to PATH to ensure we use nvm's tools
    export PATH="$nvm_bin:$PATH"

    # Verify node and npm are available
    if ! command -v node >/dev/null 2>&1; then
        log_error "node command not found after PATH update"
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm command not found after PATH update"
        return 1
    fi

    log_info "Using Node $(node --version) from nvm at: $(command -v node)"
    log_info "Using npm $(npm --version) from: $(command -v npm)"

    if command_exists corepack; then
        log_info "Enabling corepack..."
        if ! corepack enable 2>/dev/null; then
            log_warning "corepack enable failed, trying to install pnpm via npm instead"
            npm install -g pnpm 2>/dev/null || log_warning "pnpm installation failed"
        else
            log_info "Preparing pnpm via corepack..."
            if ! corepack prepare pnpm@latest --activate 2>/dev/null; then
                log_warning "corepack prepare pnpm@latest failed, trying npm install"
                npm install -g pnpm 2>/dev/null || log_warning "pnpm installation failed"
            fi
        fi
    else
        log_info "Installing pnpm via npm..."
        npm install -g pnpm 2>/dev/null || log_warning "pnpm installation failed"
    fi

    local npm_tools=(
        "tree-sitter-cli"
        "prettier"
        "typescript"
        "eslint"
    )

    if [[ ${#npm_tools[@]} -eq 0 ]]; then
        log_info "No npm global packages configured"
    else
        log_info "Installing npm globals: ${npm_tools[*]}"
        if ! npm install -g "${npm_tools[@]}" 2>&1; then
            log_warning "npm install -g failed for some packages, continuing anyway"
        else
            log_success "npm global packages installed successfully"
        fi
    fi

    log_success "Node/npm tooling setup complete"
}
