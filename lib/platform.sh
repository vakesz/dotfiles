#!/usr/bin/env bash

# Platform detection utilities

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

is_macos() {
    [[ "$(detect_os)" == "macos" ]]
}

is_linux() {
    [[ "$(detect_os)" == "linux" ]]
}

is_wsl() {
    [[ "$(detect_os)" == "wsl" ]]
}

get_distro() {
    if is_macos; then
        echo "macos"
        return
    fi

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

log() {
    printf "\033[1;34m[dotfiles]\033[0m %s\n" "$*"
}

warn() {
    printf "\033[1;33m[dotfiles]\033[0m %s\n" "$*"
}

error() {
    printf "\033[1;31m[dotfiles]\033[0m %s\n" "$*" >&2
}

success() {
    printf "\033[1;32m[dotfiles]\033[0m %s\n" "$*"
}