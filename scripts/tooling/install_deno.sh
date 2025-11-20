#!/usr/bin/env bash
#
# Installs the Deno runtime with the environment located near the installer.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"

setup_deno_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export DENO_INSTALL="${DENO_INSTALL:-${XDG_DATA_HOME}/deno}"
    export PATH="$DENO_INSTALL/bin:$PATH"
}

install_deno_runtime() {
    log_info "Ensuring Deno runtime is installed..."

    setup_deno_env

    if command_exists deno; then
        log_info "Deno already available: $(deno --version | head -n1)"
        return
    fi

    curl -fsSL https://deno.land/install.sh | sh
    setup_deno_env

    if command_exists deno; then
        log_success "Deno installed successfully"
    else
        log_warning "Deno installation finished but the 'deno' binary is still missing"
    fi
}
