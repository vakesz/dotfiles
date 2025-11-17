#!/usr/bin/env bash
#
# Installs Go runtime and tools with Go env exported nearby.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

setup_go_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
    export GOBIN="${GOBIN:-$GOPATH/bin}"
    export PATH="$GOBIN:$PATH"
}

install_go_tooling() {
    log_info "Installing Go runtime and tools..."

    setup_go_env

    if ! command_exists go; then
        log_info "Go not found; installing via platform package manager..."
        case "$PLATFORM" in
            macos)
                platform_install_with_manager "brew" "go"
                ;;
            linux|wsl)
                platform_install_with_manager "apt" "golang-go"
                ;;
        esac
    else
        log_info "Go already installed"
    fi

    if ! command_exists go; then
        die "Go installation failed"
    fi

    local go_tools=(
        "golang.org/x/tools/cmd/goimports@latest"
    )

    for tool in "${go_tools[@]}"; do
        log_info "Installing Go tool: $tool"
        GOBIN="${GOBIN:-$GOPATH/bin}" go install "$tool" || log_warning "go install $tool failed"
    done

    log_success "Go tooling ready"
}
