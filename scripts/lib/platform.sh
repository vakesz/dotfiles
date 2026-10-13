#!/usr/bin/env bash
# Operating system identity for the setup scripts.

[[ -n "${__DOTFILES_PLATFORM_LOADED:-}" ]] && return 0
__DOTFILES_PLATFORM_LOADED=1

# shellcheck source=scripts/lib/ui.sh
source "${BASH_SOURCE[0]%/*}/ui.sh"

# Print macos/linux for the current OS, or fail on anything else.
detect_platform() {
    case "$OSTYPE" in
        darwin*) printf '%s\n' "macos" ;;
        linux*) printf '%s\n' "linux" ;;
        *) return 1 ;;
    esac
}

# True on macOS (OSTYPE starts with darwin).
is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

# Abort unless the current platform is $1.
require_platform() {
    [[ "$(detect_platform)" == "$1" ]] || {
        error "This script is for $1 only"
        exit 1
    }
}
