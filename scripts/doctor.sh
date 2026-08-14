#!/usr/bin/env bash
#
# Verify that a bootstrapped machine actually ended up in the expected state.
#
# Reports what is missing rather than fixing anything. Exits non-zero when any
# check fails, so it doubles as a smoke test after a fresh setup.
#

set -uo pipefail

# -P so the path is comparable against resolve_path output below.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

source "$REPO_ROOT/scripts/lib/common.sh"

# Commands bootstrap itself requires on every platform.
CORE_COMMANDS=(git stow zsh)
# Workstation tools the Brewfile installs on macOS. On Linux they are optional.
WORKSTATION_COMMANDS=(starship fzf rg fd bat eza zoxide jq uv)
MACOS_COMMANDS=(brew gh mas topgrade)

pass() {
    printf '\033[32m  ok  \033[0m %s\n' "$1"
    (( PASS_COUNT++ ))
}

fail() {
    printf '\033[31m fail \033[0m %s\n' "$1"
    (( FAIL_COUNT++ ))
}

soft_warn() {
    printf '\033[33m warn \033[0m %s\n' "$1"
    (( WARN_COUNT++ ))
}

section() {
    printf '\n\033[1m%s\033[0m\n' "$1"
}

# Resolve a path to its real location, following symlinks in any component.
#
# Stow folds directories: it links ~/.config/zsh to the repo and leaves the
# files inside it as ordinary files, so checking only the leaf for -L reports
# correctly stowed files as missing. `pwd -P` resolves the parent chain; the
# leaf is then resolved separately, one level, which is all stow ever creates.
# This avoids depending on GNU readlink -f, which stock macOS does not ship.
resolve_path() {
    local target="$1" parent="" leaf="" destination=""

    parent="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || return 1
    leaf="$(basename "$target")"

    if [[ -L "$parent/$leaf" ]]; then
        destination="$(readlink "$parent/$leaf")" || return 1
        if [[ "$destination" == /* ]]; then
            printf '%s\n' "$destination"
        else
            printf '%s\n' "$(cd "$parent" && cd "$(dirname "$destination")" && pwd -P)/$(basename "$destination")"
        fi
        return 0
    fi

    printf '%s\n' "$parent/$leaf"
}

check_stow_links() {
    local repo_file target package rest resolved missing=0

    section "Stow symlinks"

    while IFS= read -r repo_file; do
        # The stow control file is never linked into the target tree.
        [[ "$repo_file" == "config/.stow-local-ignore" ]] && continue

        package="${repo_file%%/*}"
        rest="${repo_file#*/}"

        case "$package" in
            home) target="$HOME/$rest" ;;
            config) target="$CONFIG_TARGET/$rest" ;;
            *) continue ;;
        esac

        if [[ ! -e "$target" ]]; then
            fail "missing: $target"
            missing=1
            continue
        fi

        resolved="$(resolve_path "$target")"
        if [[ "$resolved" != "$REPO_ROOT/$repo_file" ]]; then
            fail "does not resolve into this repo: $target -> $resolved"
            missing=1
        fi
    done < <(git -C "$REPO_ROOT" ls-files home config 2>/dev/null)

    if (( missing == 0 )); then
        pass "all tracked home/ and config/ files are linked"
    fi
}

check_xdg_directories() {
    local dir

    section "XDG directories"

    set_xdg_environment_defaults
    export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"

    for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME"; do
        if [[ -d "$dir" ]]; then
            pass "exists: $dir"
        else
            fail "missing: $dir"
        fi
    done
}

check_directory_permissions() {
    local dir mode

    section "Private directory permissions"

    for dir in "$GNUPGHOME" "$HOME/.ssh"; do
        if [[ ! -d "$dir" ]]; then
            soft_warn "not present: $dir"
            continue
        fi

        # GNU coreutils stat is ahead of BSD stat on PATH here, and the two use
        # incompatible flags. Try the GNU form first, then fall back to BSD.
        mode="$(stat -c '%a' "$dir" 2>/dev/null)" || mode="$(stat -f '%Lp' "$dir" 2>/dev/null)"
        if [[ "$mode" == "700" ]]; then
            pass "0700: $dir"
        else
            fail "expected 0700, found 0$mode: $dir"
        fi
    done
}

check_commands() {
    local command_name platform=""

    section "Commands"

    for command_name in "${CORE_COMMANDS[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            pass "found: $command_name"
        else
            fail "not on PATH: $command_name"
        fi
    done

    platform="$(detect_platform 2>/dev/null)" || platform=""

    for command_name in "${WORKSTATION_COMMANDS[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            pass "found: $command_name"
        elif [[ "$platform" == "macos" ]]; then
            fail "not on PATH: $command_name"
        else
            soft_warn "not on PATH: $command_name (optional on Linux)"
        fi
    done

    [[ "$platform" == "macos" ]] || return 0

    for command_name in "${MACOS_COMMANDS[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            pass "found: $command_name"
        else
            fail "not on PATH: $command_name"
        fi
    done
}

check_shell() {
    section "Shell"

    if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
        pass "login shell is zsh"
    else
        fail "login shell is ${SHELL:-unset}, expected zsh"
    fi

    if [[ -r "$CONFIG_TARGET/zsh/.zshrc" ]]; then
        pass "zshrc readable at $CONFIG_TARGET/zsh/.zshrc"
    else
        fail "no readable zshrc at $CONFIG_TARGET/zsh/.zshrc"
    fi
}

check_brewfile() {
    [[ "$(detect_platform 2>/dev/null)" == "macos" ]] || return 0

    section "Brewfile"

    if ! command -v brew >/dev/null 2>&1; then
        fail "brew not on PATH"
        return 0
    fi

    if brew bundle check --file "$REPO_ROOT/Brewfile" >/dev/null 2>&1; then
        pass "all Brewfile entries installed"
    else
        soft_warn "Brewfile has unsatisfied entries; see: brew bundle check --file Brewfile --verbose"
    fi
}

check_macos_extras() {
    [[ "$(detect_platform 2>/dev/null)" == "macos" ]] || return 0

    section "macOS extras"

    if [[ -f /etc/pam.d/sudo_local ]] && grep -qE '^[[:space:]]*auth.*pam_tid\.so' /etc/pam.d/sudo_local; then
        pass "Touch ID for sudo enabled"
    else
        soft_warn "Touch ID for sudo not enabled (run scripts/platform/macos.sh)"
    fi

    if xcode-select -p >/dev/null 2>&1; then
        pass "Xcode Command Line Tools installed"
    else
        fail "Xcode Command Line Tools missing"
    fi

    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        pass "GitHub CLI authenticated"
    else
        soft_warn "GitHub CLI not authenticated (run: gh auth login)"
    fi
}

# Report-only. FileVault and SIP are changed from Recovery, and the firewall
# from scripts/platform/macos-hardening.sh, so doctor never touches them.
check_macos_security() {
    local firewall="/usr/libexec/ApplicationFirewall/socketfilterfw"

    [[ "$(detect_platform 2>/dev/null)" == "macos" ]] || return 0

    section "macOS security"

    if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
        pass "FileVault enabled"
    else
        fail "FileVault is off (enable in System Settings > Privacy & Security)"
    fi

    if csrutil status 2>/dev/null | grep -q "enabled"; then
        pass "System Integrity Protection enabled"
    else
        fail "SIP is disabled (re-enable from Recovery: csrutil enable)"
    fi

    if [[ ! -x "$firewall" ]]; then
        soft_warn "socketfilterfw not found; cannot check the firewall"
        return 0
    fi

    if "$firewall" --getglobalstate 2>/dev/null | grep -q "enabled"; then
        pass "Application firewall enabled"
    else
        fail "Application firewall is off (run scripts/platform/macos-hardening.sh)"
    fi
}

print_summary() {
    section "Summary"
    printf '  %d passed, %d failed, %d warnings\n\n' "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT"

    if (( FAIL_COUNT > 0 )); then
        error "Some checks failed"
        return 1
    fi

    success "All checks passed"
}

main() {
    info "Dotfiles doctor ($REPO_ROOT)"

    check_stow_links
    check_xdg_directories
    check_directory_permissions
    check_commands
    check_shell
    check_brewfile
    check_macos_extras
    check_macos_security

    print_summary
}

main "$@"
