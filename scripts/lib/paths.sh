#!/usr/bin/env bash
# Repo paths, XDG defaults, and the runtime directories bootstrap creates.

[[ -n "${__DOTFILES_PATHS_LOADED:-}" ]] && return 0
__DOTFILES_PATHS_LOADED=1

DOTFILES_ROOT="$(cd "${BASH_SOURCE[0]%/*}/../.." && pwd -P)"
readonly DOTFILES_ROOT
# shellcheck disable=SC2034 # read by the scripts that source this file
readonly DOTFILES_BREWFILE="$DOTFILES_ROOT/Brewfile"

# Every export here must match the zsh environment; check.sh compares them all.
set_xdg_environment_defaults() {
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
    export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"
    export PNPM_HOME="${PNPM_HOME:-$XDG_DATA_HOME/pnpm}"
    export CCACHE_DIR="${CCACHE_DIR:-$XDG_CACHE_HOME/ccache}"
    export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
    export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
    export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$XDG_DATA_HOME/gradle}"

    DOTFILES_STATE_DIRS=(
        "$XDG_STATE_HOME/zsh"
        "$XDG_CACHE_HOME/zsh"
        "$XDG_STATE_HOME/less"
        "$GNUPGHOME"
        "$PNPM_HOME/bin"
        "$CCACHE_DIR"
        "$CARGO_HOME"
        "$RUSTUP_HOME"
        "$GRADLE_USER_HOME"
    )
}

# Print "package<TAB>target" for every stow package on this platform. The
# single source for what bootstrap links and what doctor verifies.
stow_package_targets() {
    : "${XDG_CONFIG_HOME:?call set_xdg_environment_defaults first}"
    printf '%s\t%s\n' \
        home "$HOME" \
        config "$XDG_CONFIG_HOME" \
        data "$XDG_DATA_HOME"
    # Checks OSTYPE directly so this file doesn't depend on platform.sh.
    if [[ "$OSTYPE" == darwin* ]]; then
        printf '%s\t%s\n' config-macos "$XDG_CONFIG_HOME"
    fi
}

ensure_xdg_runtime_directories() {
    set_xdg_environment_defaults

    mkdir -p \
        "$XDG_CONFIG_HOME" \
        "$XDG_DATA_HOME" \
        "$XDG_STATE_HOME" \
        "$XDG_CACHE_HOME" \
        "$XDG_BIN_HOME" \
        "${DOTFILES_STATE_DIRS[@]}"
    chmod 700 "$GNUPGHOME"
}
