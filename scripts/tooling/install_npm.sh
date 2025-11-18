#!/usr/bin/env bash
#
# Installs Node via nvm, enables pnpm, and installs curated npm tools.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

setup_node_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export NVM_DIR="${NVM_DIR:-${XDG_DATA_HOME}/nvm}"
    export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME}/pnpm}"
    export PATH="$PNPM_HOME:$PATH"
}

install_npm_tooling() {
    log_info "Setting up Node/npm tooling..."

    setup_node_env

    if [[ -z "${NVM_DIR:-}" ]]; then
        die "NVM_DIR is not set; cannot install Node"
    fi

    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck disable=SC1090
        source "$NVM_DIR/nvm.sh"
    fi

    if ! command_exists nvm; then
        log_info "nvm not installed, fetching installer..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        # shellcheck disable=SC1090
        source "$NVM_DIR/nvm.sh"
    fi

    if ! command_exists node; then
        log_info "Installing Node LTS via nvm..."
        if ! nvm install --lts; then
            log_warning "nvm install --lts failed (network issue?)"
        fi
    fi

    nvm alias default 'lts/*' >/dev/null 2>&1 || true
    nvm use --lts >/dev/null 2>&1 || true

    if command_exists corepack; then
        if ! corepack enable; then
            log_warning "corepack enable failed"
        fi

        if ! corepack prepare pnpm@latest --activate; then
            log_warning "corepack prepare pnpm@latest failed (network?)"
        fi
    else
        log_info "Installing pnpm via npm..."
        npm install -g pnpm
    fi

    local npm_tools=(
        "tree-sitter-cli"
        "prettier"
    )

    if [[ ${#npm_tools[@]} -eq 0 ]]; then
        log_info "No npm global packages configured"
    else
        log_info "Installing npm globals: ${npm_tools[*]}"
        npm install -g "${npm_tools[@]}" || log_warning "npm install -g failed"
    fi
}
