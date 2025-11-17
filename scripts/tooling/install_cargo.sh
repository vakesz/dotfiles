#!/usr/bin/env bash
#
# Installs Rust toolchain (rustup) and curated cargo utilities.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

setup_rust_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export RUSTUP_HOME="${RUSTUP_HOME:-${XDG_DATA_HOME}/rustup}"
    export CARGO_HOME="${CARGO_HOME:-${XDG_DATA_HOME}/cargo}"
    export PATH="$CARGO_HOME/bin:$PATH"
}

install_rust_tooling() {
    log_info "Ensuring Rust and Cargo toolchain..."

    setup_rust_env

    if ! command_exists rustup; then
        log_info "Rustup not found, installing via official script..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

        if [[ -f "$RUSTUP_HOME/env" ]]; then
            # shellcheck disable=SC1090
            source "$RUSTUP_HOME/env"
        fi
    else
        log_info "Rustup already installed"
    fi

    if [[ -f "$RUSTUP_HOME/env" ]]; then
        # shellcheck disable=SC1090
        source "$RUSTUP_HOME/env"
    elif [[ -f "$HOME/.cargo/env" ]]; then
        # shellcheck disable=SC1090
        source "$HOME/.cargo/env"
    fi

    if ! command_exists cargo; then
        die "Cargo is not available after installing rustup"
    fi

    local cargo_tools=(
        "tealdeer"
        "zoxide"
        "topgrade"
        "cargo-update"
        "cargo-cache"
        "stylua"
    )

    for pkg in "${cargo_tools[@]}"; do
        log_info "Installing cargo package: $pkg"

        # Special handling for topgrade on macOS due to mac-notification-sys linking issues
        if [[ "$pkg" == "topgrade" ]] && [[ "$(uname -s)" == "Darwin" ]]; then
            RUSTFLAGS="-C link-arg=-framework -C link-arg=AppKit -C link-arg=-framework -C link-arg=CoreServices" \
                cargo install --locked "$pkg" || log_warning "cargo install $pkg failed"
        else
            cargo install --locked "$pkg" || log_warning "cargo install $pkg failed"
        fi
    done

    log_success "Rust toolchain setup complete"
}
