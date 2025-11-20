#!/usr/bin/env bash
#
# Installs Python runtime, pipx, and a curated list of pip packages.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"

setup_python_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export PIPX_HOME="${PIPX_HOME:-${XDG_DATA_HOME}/pipx}"
    export PATH="$PIPX_HOME/bin:$PATH"
}

install_pip_tooling() {
    log_info "Installing Python ecosystem tooling..."

    setup_python_env

    if ! command_exists python3; then
        log_info "Python3 missing, installing via package manager..."
        case "$PLATFORM" in
            macos)
                platform_install_with_manager "brew" "python@3.13"
                ;;
            linux|wsl)
                platform_install_with_manager "apt" "python3" "python3-pip" "pipx"
                ;;
        esac
    fi

    if ! command_exists pipx; then
        log_info "Installing pipx..."
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath >/dev/null 2>&1 || true
        setup_python_env
    fi

    if ! command_exists pipx; then
        die "pipx installation failed"
    fi

    local pip_tools=(
        "pre-commit"
        "ruff"
        "black"
    )

    if [[ ${#pip_tools[@]} -eq 0 ]]; then
        log_info "No pip-based tools configured"
        return
    fi

    for tool in "${pip_tools[@]}"; do
        log_info "Installing pipx package $tool"
        pipx install --force "$tool" || log_warning "pipx install $tool failed"
    done

    log_success "Python tools installed"
}
