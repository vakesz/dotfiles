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

    if [[ ! -t 0 || ! -t 1 ]]; then
        return 1
    fi

    read -r -n 1 -p $'\n'"$1"$' (y/N) ' answer || true
    echo ""
    [[ "$answer" =~ ^[Yy]$ ]]
}

run_if_needed() {
    local check_fn="$2" action_fn="$3" prompt="${4:-$1?}" applied_label="${5:-$1 already applied}"

    if "$check_fn"; then
        info "$applied_label"
        return 0
    fi

    if confirm "$prompt"; then
        "$action_fn"
    fi
}

run_if_confirmed() {
    local prompt="$1" action_fn="$2"

    if confirm "$prompt"; then
        "$action_fn"
    fi
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
