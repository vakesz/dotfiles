#!/usr/bin/env bash
#
# XDG environment defaults and the runtime directories owned by this repo.
#

if [[ -n "${_DOTFILES_XDG_LOADED:-}" ]]; then
    return 0
fi
_DOTFILES_XDG_LOADED=1

set_xdg_environment_defaults() {
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
}

ensure_xdg_runtime_directories() {
    set_xdg_environment_defaults
    export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"

    mkdir -p \
        "$XDG_CONFIG_HOME" \
        "$XDG_DATA_HOME" \
        "$XDG_STATE_HOME" \
        "$XDG_CACHE_HOME" \
        "$XDG_BIN_HOME" \
        "$XDG_STATE_HOME/zsh" \
        "$XDG_CACHE_HOME/zsh" \
        "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
}
