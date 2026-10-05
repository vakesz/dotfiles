#!/usr/bin/env bash
# Check that a bootstrapped machine is in the expected state. It only reports,
# never fixes, and exits non-zero on any failure, so it works as a smoke test.

set -uo pipefail

# shellcheck source=scripts/lib/paths.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/paths.sh"
# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/platform.sh
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
# shellcheck source=scripts/lib/macos-state.sh
is_macos && source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"

CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"

# Required by bootstrap on every platform.
CORE_COMMANDS=(git stow zsh)
# Installed by the Brewfile on macOS; optional on Linux.
WORKSTATION_COMMANDS=(starship fzf rg fd bat eza zoxide jq uv tldr yq direnv ccache git-lfs node pnpm bun rustup)
MACOS_COMMANDS=(brew dockutil gh mas topgrade)

has_command() {
    command -v "$1" >/dev/null 2>&1
}

quietly() {
    "$@" >/dev/null 2>&1
}

verify() {
    local ok="$1" bad="$2" reporter="$3"
    shift 3

    if "$@"; then
        pass "$ok"
    else
        "$reporter" "$bad"
    fi
}

check_stow_links() {
    local repo_file target package rest resolved missing=0

    section "Stow symlinks"

    while IFS= read -r repo_file; do
        # Check the working tree as it is: skip tracked files removed by an
        # uncommitted rename, and include their untracked replacements.
        [[ -e "$DOTFILES_ROOT/$repo_file" || -L "$DOTFILES_ROOT/$repo_file" ]] || continue

        # Stow's ignore file is never linked.
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

        # Stow may link a parent directory instead of the file, so resolve the
        # whole path. realpath ships with macOS 13+ and Linux.
        resolved="$(realpath "$target")"
        if [[ "$resolved" != "$DOTFILES_ROOT/$repo_file" ]]; then
            fail "does not resolve into this repo: $target -> $resolved"
            missing=1
        fi
    done < <(git -C "$DOTFILES_ROOT" ls-files --cached --others --exclude-standard home config 2>/dev/null | sort -u)

    if ((missing == 0)); then
        pass "all managed home/ and config/ files are linked"
    fi
}

check_xdg_directories() {
    local dir

    section "XDG directories"

    for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "${DOTFILES_STATE_DIRS[@]}"; do
        verify "exists: $dir" "missing: $dir" fail test -d "$dir"
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

        # GNU and BSD stat take different flags. Try GNU first, then BSD (macOS).
        mode="$(stat -c '%a' "$dir" 2>/dev/null)" || mode="$(stat -f '%Lp' "$dir" 2>/dev/null)"
        verify "0700: $dir" "expected 0700, found 0$mode: $dir" fail test "$mode" = "700"
    done
}

check_commands() {
    local command_name

    section "Commands"

    for command_name in "${CORE_COMMANDS[@]}"; do
        verify "found: $command_name" "not on PATH: $command_name" fail has_command "$command_name"
    done

    for command_name in "${WORKSTATION_COMMANDS[@]}"; do
        if has_command "$command_name"; then
            pass "found: $command_name"
        elif is_macos; then
            fail "not on PATH: $command_name"
        else
            soft_warn "not on PATH: $command_name (optional on Linux)"
        fi
    done

    is_macos || return 0

    for command_name in "${MACOS_COMMANDS[@]}"; do
        verify "found: $command_name" "not on PATH: $command_name" fail has_command "$command_name"
    done
}

check_shell() {
    section "Shell"

    verify "login shell is zsh" "login shell is ${SHELL:-unset}, expected zsh" \
        fail test "$(basename "${SHELL:-}")" = "zsh"
    verify "zshrc readable at $CONFIG_TARGET/zsh/.zshrc" "no readable zshrc at $CONFIG_TARGET/zsh/.zshrc" \
        fail test -r "$CONFIG_TARGET/zsh/.zshrc"
}

check_brewfile() {
    section "Brewfile"

    if ! has_command brew; then
        fail "brew not on PATH"
        return 0
    fi

    verify "all Brewfile entries installed" \
        "Brewfile has unsatisfied entries; see: brew bundle check --file Brewfile --verbose" \
        soft_warn quietly brew bundle check --file "$DOTFILES_BREWFILE"
}

check_macos_tooling() {
    section "macOS tooling"

    verify "Touch ID for sudo enabled" "Touch ID for sudo not enabled (run scripts/platform/macos.sh)" \
        soft_warn macos_touch_id_sudo_enabled
    verify "Xcode Command Line Tools installed" "Xcode Command Line Tools missing" \
        fail macos_xcode_cli_tools_installed
    verify "full Xcode installation available" "full Xcode installation not available" \
        soft_warn macos_full_xcode_installed
    verify "GitHub CLI authenticated" "GitHub CLI not authenticated (run: gh auth login)" \
        soft_warn quietly gh auth status
}

# Report only. macos-hardening.sh can fix FileVault, security updates and the
# firewall; SIP can only be changed from Recovery.
check_macos_security() {
    section "macOS security"

    verify "FileVault enabled" "FileVault is off (run scripts/platform/macos-hardening.sh)" \
        fail macos_filevault_enabled
    verify "System Integrity Protection enabled" "SIP is disabled (re-enable from Recovery: csrutil enable)" \
        fail macos_sip_enabled
    # spctl can no longer re-enable Gatekeeper; only System Settings can.
    verify "Gatekeeper assessments enabled" "Gatekeeper is off (re-enable in System Settings > Privacy & Security)" \
        fail macos_gatekeeper_enabled
    verify "Security responses install automatically" "Security responses are not automatic (run scripts/platform/macos-hardening.sh)" \
        soft_warn macos_automatic_security_updates_enabled

    if ! macos_firewall_available; then
        soft_warn "socketfilterfw not found; cannot check the firewall"
    elif macos_firewall_enabled; then
        pass "Application firewall enabled"
    elif macos_mdm_managed; then
        # socketfilterfw refuses command-line changes on a managed Mac, so the
        # hardening script can't fix this.
        soft_warn "Application firewall is off and this Mac is MDM-managed; ask IT"
    else
        fail "Application firewall is off (run scripts/platform/macos-hardening.sh)"
    fi

    if macos_firewall_stealth_mode_enabled; then
        pass "Firewall Stealth Mode enabled"
    elif macos_mdm_managed; then
        soft_warn "Firewall Stealth Mode is off or managed by a profile; check System Settings or ask IT"
    else
        soft_warn "Firewall Stealth Mode is off (run scripts/platform/macos-hardening.sh)"
    fi
}

print_summary() {
    section "Summary"
    printf '  %d passed, %d failed, %d warnings\n\n' "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT"

    if ((FAIL_COUNT > 0)); then
        error "Some checks failed"
        return 1
    fi

    success "All checks passed"
}

main() {
    info "Dotfiles doctor ($DOTFILES_ROOT)"

    set_xdg_environment_defaults

    check_stow_links
    check_xdg_directories
    check_directory_permissions
    check_commands
    check_shell

    if is_macos; then
        check_brewfile
        check_macos_tooling
        check_macos_security
    fi

    print_summary
}

main "$@"
