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

# Print the login shell's basename. $SHELL stays stale until the next login,
# so ask the user database first.
login_shell_name() {
    local shell_path="" user_name="${USER:-$(id -un 2>/dev/null)}"

    if command -v getent >/dev/null 2>&1; then
        shell_path="$(getent passwd "$user_name" 2>/dev/null | awk -F: '{print $7}')"
    elif command -v dscl >/dev/null 2>&1; then
        shell_path="$(dscl . -read "/Users/$user_name" UserShell 2>/dev/null | awk '{print $2}')"
    fi

    shell_path="${shell_path:-${SHELL:-}}"
    printf '%s\n' "${shell_path##*/}"
}

# Abort unless the current platform is $1.
require_platform() {
    [[ "$(detect_platform)" == "$1" ]] || die "This script is for $1 only"
}
