#!/usr/bin/env bash
#
# Shared environment helpers for tooling installers.
#

tooling_setup_xdg_dirs() {
    # Base XDG paths (respect any user overrides)
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

    # XDG-compliant locations for user binaries (optional)
    export XDG_BIN_HOME="${XDG_BIN_HOME:-${XDG_DATA_HOME}/bin}"

    # SwiftPM XDG compliance
    export SWIFTPM_HOME="${XDG_DATA_HOME}/swiftpm"

    # Yarn XDG compliance
    export YARN_CACHE_FOLDER="${XDG_CACHE_HOME}/yarn"
    export YARN_GLOBAL_FOLDER="${XDG_DATA_HOME}/yarn"

    # Common tool homes (defaults attached to XDG_DATA_HOME)
    export CARGO_HOME="${CARGO_HOME:-${XDG_DATA_HOME}/cargo}"
    export RUSTUP_HOME="${RUSTUP_HOME:-${XDG_DATA_HOME}/rustup}"
    export PIPX_HOME="${PIPX_HOME:-${XDG_DATA_HOME}/pipx}"
    export GOPATH="${GOPATH:-${XDG_DATA_HOME}/go}"
    export GOBIN="${GOBIN:-${GOPATH}/bin}"
    export DENO_INSTALL="${DENO_INSTALL:-${XDG_DATA_HOME}/deno}"
    export NVM_DIR="${NVM_DIR:-${XDG_DATA_HOME}/nvm}"
    export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME}/pnpm}"

    # Add the user XDG bin dir to PATH and ensure it exists so installers can drop
    # executables there and we can reference it in prompts and scripts.
    export PATH="$XDG_BIN_HOME:$PATH"

    # Ensure directories exist
    mkdir -p "$XDG_DATA_HOME" \
             "$XDG_CONFIG_HOME" \
             "$XDG_CACHE_HOME" \
             "$SWIFTPM_HOME" \
             "$YARN_CACHE_FOLDER" \
             "$YARN_GLOBAL_FOLDER" \
             "$XDG_BIN_HOME" \
             "$CARGO_HOME" \
             "$RUSTUP_HOME" \
             "$PIPX_HOME" \
             "$GOPATH" \
             "$GOBIN" \
             "$DENO_INSTALL" \
             "$NVM_DIR" \
             "$PNPM_HOME"
}

tooling_ensure_local_bin() {
    # Ensure XDG bin is present in PATH. Defaults to $XDG_DATA_HOME/bin.
    if [[ ":$PATH:" != *":$XDG_BIN_HOME:"* ]]; then
        export PATH="$XDG_BIN_HOME:$PATH"
    fi
    # Ensure the directory exists
    mkdir -p "$XDG_BIN_HOME"
}
