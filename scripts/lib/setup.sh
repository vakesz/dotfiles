#!/usr/bin/env bash
#
# Shared control-flow helpers for the setup scripts: status output, prompts,
# and platform guards.
#

if [[ -n "${_DOTFILES_SETUP_LOADED:-}" ]]; then
    return 0
fi
_DOTFILES_SETUP_LOADED=1

info() {
    printf '\033[34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\033[32m[OK]\033[0m %s\n' "$1"
}

warn() {
    printf '\033[33m[WARN]\033[0m %s\n' "$1" >&2
}

error() {
    printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2
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
    # Read a full line so Enter is consumed here; `read -n 1` would leave a
    # newline for the next prompt and skip it as No.
    printf '\n%s (y/N) ' "$1"

    if ! IFS= read -r -t "$timeout" answer; then
        printf '\n'
        warn "No confirmation input received; defaulting to No"
        return 1
    fi

    case "$answer" in
        y | Y | yes | YES | Yes) return 0 ;;
        *) return 1 ;;
    esac
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
