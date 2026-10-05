#!/usr/bin/env bash
# Status messages, prompts and check results. The only file in scripts/ that
# prints ANSI colors.

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

is_interactive() {
    [[ -t 0 && -t 1 ]]
}

confirm() {
    local answer="n"
    local timeout="${DOTFILES_CONFIRM_TIMEOUT:-30}"

    is_interactive || return 1
    [[ "$timeout" =~ ^[0-9]+$ ]] || timeout=30

    printf '\n%s (y/N) ' "$1"

    # Read a whole line so Enter is consumed. `read -n 1` would leave the newline
    # behind, and the next prompt would read it as No.
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

# Always returns 0, so a declined or failed step doesn't abort a `set -e` script.
offer() {
    local prompt="$1"
    shift

    confirm "$prompt" || return 0
    "$@" || warn "$1 did not complete"
}

offer_if_missing() {
    local prompt="$1" check_fn="$2" action_fn="$3" already_message="$4"

    if "$check_fn"; then
        info "$already_message"
        return 0
    fi

    offer "$prompt" "$action_fn"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 && return 0
    info "$1 not installed; skipping ${2:-$1}"
    return 1
}

PASS_COUNT="${PASS_COUNT:-0}"
FAIL_COUNT="${FAIL_COUNT:-0}"
WARN_COUNT="${WARN_COUNT:-0}"
SKIP_COUNT="${SKIP_COUNT:-0}"

section() {
    printf '\n\033[1m%s\033[0m\n' "$1"
}

# `((X += 1))`, not `((X++))`: the latter returns 1 when X is 0, which aborts
# `set -e` callers.
pass() {
    printf '\033[32m  ok  \033[0m %s\n' "$1"
    ((PASS_COUNT += 1))
}

fail() {
    printf '\033[31m fail \033[0m %s\n' "$1"
    ((FAIL_COUNT += 1))
}

soft_warn() {
    printf '\033[33m warn \033[0m %s\n' "$1"
    ((WARN_COUNT += 1))
}

skip() {
    printf '\033[34m skip \033[0m %s\n' "$1"
    ((SKIP_COUNT += 1))
}
