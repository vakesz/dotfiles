#!/usr/bin/env bash

info() {
    printf '\033[34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\033[32m[OK]\033[0m %s\n' "$1"
}

warn() {
    printf '\033[33m[WARN]\033[0m %s\n' "$1"
}

error() {
    printf '\033[31m[ERROR]\033[0m %s\n' "$1"
}

confirm() {
    local answer="n"
    local timeout="${DOTFILES_CONFIRM_TIMEOUT:-30}"

    if [[ ! -t 0 || ! -t 1 ]]; then
        return 1
    fi

    if [[ ! "$timeout" =~ ^[0-9]+$ ]]; then
        timeout=30
    fi

    # Print the prompt explicitly so it is always visible in interactive terminals.
    printf '\n%s (y/N) ' "$1"

    if ! IFS= read -r -n 1 -t "$timeout" answer; then
        echo ""
        warn "No confirmation input received; defaulting to No"
        return 1
    fi

    echo ""
    [[ "$answer" =~ ^[Yy]$ ]]
}

confirm_and_run() {
    local prompt="$1"
    shift

    if confirm "$prompt"; then
        "$@"
    fi
}

prompt_if_missing() {
    local check_fn="$1" action_fn="$2" prompt="$3" already_message="$4"

    if "$check_fn"; then
        info "$already_message"
        return 0
    fi

    confirm_and_run "$prompt" "$action_fn"
}

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

ensure_javascript_environment() {
    if [[ -z "${XDG_CONFIG_HOME:-}" || -z "${XDG_DATA_HOME:-}" || -z "${XDG_STATE_HOME:-}" || -z "${XDG_CACHE_HOME:-}" || -z "${XDG_BIN_HOME:-}" ]]; then
        set_xdg_environment_defaults
    fi

    export FNM_DIR="${FNM_DIR:-$XDG_DATA_HOME/fnm}"
    export PNPM_HOME="${PNPM_HOME:-$XDG_DATA_HOME/pnpm}"

    case ":$PATH:" in
        *":$PNPM_HOME/bin:"*) ;;
        *) export PATH="$PNPM_HOME/bin:$PATH" ;;
    esac
}

load_fnm_environment() {
    ensure_javascript_environment
    command -v fnm >/dev/null 2>&1 || return 1
    eval "$(fnm env --shell bash --corepack-enabled)"
}

fnm_managed_node_available() {
    load_fnm_environment || return 1

    local node_path="" corepack_path=""
    node_path="$(command -v node 2>/dev/null)" || return 1
    corepack_path="$(command -v corepack 2>/dev/null)" || return 1

    [[ -n "${FNM_MULTISHELL_PATH:-}" ]] || return 1
    [[ "$node_path" == "$FNM_MULTISHELL_PATH/"* ]] || return 1
    [[ "$corepack_path" == "$FNM_MULTISHELL_PATH/"* ]]
}

install_node_with_fnm() {
    load_fnm_environment || {
        warn "fnm not available; skipping Node.js setup"
        return 0
    }

    info "Installing latest Node.js LTS with fnm..."
    fnm install --lts --corepack-enabled --use

    local node_version=""
    node_version="$(node --version)"
    fnm default "$node_version"
    success "Node.js $node_version installed and selected with fnm"
}

pnpm_available() {
    # Sets up the JS environment even when fnm itself is missing.
    load_fnm_environment >/dev/null 2>&1 || true
    command -v pnpm >/dev/null 2>&1
}

enable_pnpm_with_corepack() {
    fnm_managed_node_available || {
        warn "No fnm-managed Node.js runtime available; skipping pnpm setup"
        return 0
    }

    info "Enabling pnpm via corepack..."
    corepack enable pnpm
    success "pnpm enabled"
}

offer_javascript_toolchain_setup() {
    if ! command -v fnm >/dev/null 2>&1; then
        info "fnm not available; skipping Node.js and pnpm setup"
        return 0
    fi

    prompt_if_missing \
        fnm_managed_node_available \
        install_node_with_fnm \
        "Install latest Node.js LTS with fnm?" \
        "fnm-managed Node.js already available"

    prompt_if_missing \
        pnpm_available \
        enable_pnpm_with_corepack \
        "Enable pnpm via corepack?" \
        "pnpm already available"
}

detect_platform() {
    case "$OSTYPE" in
        darwin*)
            printf '%s\n' "macos"
            ;;
        linux*)
            printf '%s\n' "linux"
            ;;
        *)
            return 1
            ;;
    esac
}

require_platform() {
    local expected="$1" actual=""
    actual="$(detect_platform 2>/dev/null)" || actual=""
    if [[ "$actual" != "$expected" ]]; then
        error "This script is for $expected only"
        exit 1
    fi
}
