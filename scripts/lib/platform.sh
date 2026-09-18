#!/usr/bin/env bash
# Operating system identity for the setup scripts.

# shellcheck source=scripts/lib/ui.sh
source "${BASH_SOURCE[0]%/*}/ui.sh"

detect_platform() {
    case "$OSTYPE" in
        darwin*) printf '%s\n' "macos" ;;
        linux*) printf '%s\n' "linux" ;;
        *) return 1 ;;
    esac
}

is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

require_platform() {
    [[ "$(detect_platform)" == "$1" ]] || {
        error "This script is for $1 only"
        exit 1
    }
}
