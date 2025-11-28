#!/usr/bin/env bash
#
# Installs Rust toolchain (rustup) and curated cargo utilities.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"

# Sets up Rust environment variables and PATH for rustup and cargo
setup_rust_env() {
    tooling_setup_xdg_dirs
    tooling_ensure_local_bin

    export RUSTUP_HOME="${RUSTUP_HOME:-${XDG_DATA_HOME}/rustup}"
    export CARGO_HOME="${CARGO_HOME:-${XDG_DATA_HOME}/cargo}"
    export PATH="$CARGO_HOME/bin:$PATH"
}

# Installs Rust toolchain via rustup and curated cargo packages
install_rust_tooling() {
    log_info "Ensuring Rust and Cargo toolchain..."

    setup_rust_env

    if ! command_exists rustup; then
        log_info "Rustup not found, installing via official script..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

        if [[ -f "$RUSTUP_HOME/env" ]]; then
            # shellcheck disable=SC1090,SC1091
            source "$RUSTUP_HOME/env"
        fi
    else
        log_info "Rustup already installed"
    fi

    if [[ -f "$RUSTUP_HOME/env" ]]; then
        # shellcheck disable=SC1090,SC1091
        source "$RUSTUP_HOME/env"
    elif [[ -f "$HOME/.cargo/env" ]]; then
        # Legacy fallback for non-XDG Rust installations
        # shellcheck disable=SC1090,SC1091
        source "$HOME/.cargo/env"
    fi

    if ! command_exists cargo; then
        die "Cargo is not available after installing rustup"
    fi

    # Default set of cargo tools to install. `topgrade` is a user-facing
    # tool that we prefer to install via the platform package manager on
    # macOS (Homebrew) so avoid installing it via Cargo there.
    local cargo_tools=(
        "tealdeer"
        "zoxide"
        "cargo-update"
        "cargo-cache"
        "stylua"
    )

    # Add topgrade on non-macOS platforms only (we install via Homebrew on macOS)
    if [[ "$PLATFORM" != "macos" ]]; then
        cargo_tools+=("topgrade")
    else
        log_info "Skipping cargo installation of topgrade on macOS (use Homebrew)"
    fi

    for pkg in "${cargo_tools[@]}"; do
        log_info "Installing cargo package: $pkg"

        cargo install --locked "$pkg" || log_warning "cargo install $pkg failed"
    done

    log_success "Rust toolchain setup complete"
}
