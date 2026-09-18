#!/usr/bin/env bash
# The repository's own paths, the XDG environment and the runtime directories this repo owns.

DOTFILES_ROOT="$(cd "${BASH_SOURCE[0]%/*}/../.." && pwd -P)"
# shellcheck disable=SC2034 # read by the scripts that source this file
DOTFILES_BREWFILE="$DOTFILES_ROOT/Brewfile"

set_xdg_environment_defaults() {
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
    export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"

    DOTFILES_STATE_DIRS=(
        "$XDG_STATE_HOME/zsh"
        "$XDG_CACHE_HOME/zsh"
        "$XDG_STATE_HOME/less"
        "$XDG_STATE_HOME/psql"
        "$GNUPGHOME"
    )
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
