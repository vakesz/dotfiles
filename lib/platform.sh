#!/usr/bin/env bash

# Platform detection utilities with caching for performance

# Cache OS detection result to avoid repeated filesystem access
_DETECTED_OS=""

detect_os() {
    # Return cached value if already detected
    if [[ -n "$_DETECTED_OS" ]]; then
        echo "$_DETECTED_OS"
        return 0
    fi

    # Detect OS and cache result
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _DETECTED_OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
            _DETECTED_OS="wsl"
        else
            _DETECTED_OS="linux"
        fi
    else
        _DETECTED_OS="unknown"
    fi

    echo "$_DETECTED_OS"
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