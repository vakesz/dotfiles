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
    read -r -n 1 -p $'\n'"$1"$' (y/N) ' answer || true
    echo ""
    [[ "$answer" =~ ^[Yy]$ ]]
}

run_if_needed() {
    local label="$1" check_fn="$2" action_fn="$3"

    if "$check_fn"; then
        info "$label already applied"
        return 0
    fi

    confirm "$label?" && "$action_fn"
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
