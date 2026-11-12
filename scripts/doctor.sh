#!/usr/bin/env bash
# Check that a bootstrapped machine is in the expected state. It only reports,
# never fixes, and exits non-zero on any failure, so it works as a smoke test.

# Deliberately no -e: every check must run so the summary counts all results.
set -uo pipefail

# shellcheck source=scripts/lib/paths.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/paths.sh"
# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/platform.sh
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
# shellcheck source=scripts/lib/macos-state.sh
is_macos && source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"

# Required by bootstrap on every platform.
CORE_COMMANDS=(git stow zsh)
# Installed by the Brewfile on macOS; optional on Linux. "a|b" accepts either
# name: Debian and Ubuntu ship fd as fdfind and bat as batcat.
WORKSTATION_COMMANDS=(starship fzf rg "fd|fdfind" "bat|batcat" eza zoxide jq uv tldr yq direnv ccache git-lfs node pnpm bun rustup)
MACOS_COMMANDS=(brew dockutil gh mas topgrade)

# True when $1 is on PATH.
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Print the first name in "a|b" that is on PATH; fail if none is.
find_command() {
    local name names=()

    IFS='|' read -r -a names <<<"$1"
    for name in "${names[@]}"; do
        if has_command "$name"; then
            printf '%s\n' "$name"
            return 0
        fi
    done
    return 1
}

# Run "$@" discarding all output; report only success/failure.
quietly() {
    "$@" >/dev/null 2>&1
}

# Run a check ("$@" after the first three args) and record pass/fail via reporter.
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
    local packages=() targets=() i listing=""

    section "Stow symlinks"

    while IFS=$'\t' read -r package target; do
        packages+=("$package")
        targets+=("$target")
    done < <(stow_package_targets)

    # An empty list would pass vacuously, so a git failure (its error is left
    # on stderr) or no files at all is a failure.
    if ! listing="$(git -C "$DOTFILES_ROOT" ls-files --cached --others --exclude-standard -- "${packages[@]}" | sort -u)"; then
        fail "git ls-files failed; cannot list the managed files"
        return 0
    fi
    if [[ -z "$listing" ]]; then
        fail "git ls-files found no managed files in ${packages[*]}"
        return 0
    fi

    while IFS= read -r repo_file; do
        # Check the working tree as it is: skip tracked files removed by an
        # uncommitted rename, and include their untracked replacements.
        [[ -e "$DOTFILES_ROOT/$repo_file" || -L "$DOTFILES_ROOT/$repo_file" ]] || continue

        package="${repo_file%%/*}"
        rest="${repo_file#*/}"
        target=""
        for i in "${!packages[@]}"; do
            if [[ "${packages[i]}" == "$package" ]]; then
                target="${targets[i]}/$rest"
                break
            fi
        done
        [[ -n "$target" ]] || continue

        if [[ ! -e "$target" ]]; then
            fail "missing: $target"
            missing=1
            continue
        fi

        # Bootstrap links files individually (--no-folding), but resolve the
        # whole path anyway in case an older checkout used directory folding.
        resolved="$(realpath "$target")"
        if [[ "$resolved" != "$DOTFILES_ROOT/$repo_file" ]]; then
            fail "does not resolve into this repo: $target -> $resolved"
            missing=1
        fi
    done <<<"$listing"

    if ((missing == 0)); then
        pass "all managed files in ${packages[*]} are linked"
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
    local command_name found

    section "Commands"

    for command_name in "${CORE_COMMANDS[@]}"; do
        verify "found: $command_name" "not on PATH: $command_name" fail has_command "$command_name"
    done

    for command_name in "${WORKSTATION_COMMANDS[@]}"; do
        if found="$(find_command "$command_name")"; then
            if [[ "$found" == "${command_name%%|*}" ]]; then
                pass "found: $found"
            else
                pass "found: ${command_name%%|*} (as $found)"
            fi
        elif is_macos; then
            fail "not on PATH: ${command_name//|/ or }"
        else
            soft_warn "not on PATH: ${command_name//|/ or } (optional on Linux)"
        fi
    done

    is_macos || return 0

    for command_name in "${MACOS_COMMANDS[@]}"; do
        verify "found: $command_name" "not on PATH: $command_name" fail has_command "$command_name"
    done
}

check_shell() {
    local current_shell="" reporter=fail

    section "Shell"

    # CI runners log in with bash and can't change it, so only warn there.
    [[ -n "${CI:-}" ]] && reporter=soft_warn

    current_shell="$(login_shell_name)"
    verify "login shell is zsh" "login shell is ${current_shell:-unset}, expected zsh" \
        "$reporter" test "$current_shell" = "zsh"
    verify "zshrc readable at $XDG_CONFIG_HOME/zsh/.zshrc" "no readable zshrc at $XDG_CONFIG_HOME/zsh/.zshrc" \
        fail test -r "$XDG_CONFIG_HOME/zsh/.zshrc"
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
    verify "launchd env agent installed and loaded" "launchd env agent not installed or not loaded (run scripts/platform/macos.sh)" \
        soft_warn macos_launchd_env_agent_loaded
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

# Reads what Spotlight actually indexed, so it catches exclusions that never
# took effect and items indexed before a path was excluded.
check_macos_spotlight() {
    local path count clean=1

    section "Spotlight"

    # One pass over the index: the first input is the existing exclusion
    # paths, the second every indexed item under $HOME.
    while IFS=$'\t' read -r count path; do
        soft_warn "Spotlight indexes $count items under $path (run scripts/platform/macos.sh; if it's already on the Privacy list, rebuild the index: sudo mdutil -E /)"
        clean=0
    done < <(awk '
        NR == FNR { if ($0 != "") prefixes[++n] = $0; next }
        { for (i = 1; i <= n; i++) if (index($0, prefixes[i] "/") == 1) { hits[i]++; break } }
        END { for (i = 1; i <= n; i++) if (hits[i]) printf "%d\t%s\n", hits[i], prefixes[i] }
    ' <(while IFS= read -r path; do [[ -d "$path" ]] && printf '%s\n' "$path"; done < <(macos_spotlight_exclusion_paths)) \
        <(macos_spotlight_indexed_home))

    ((clean)) && pass "no excluded dev paths are indexed"
    return 0
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
        check_macos_spotlight
    fi

    print_summary
}

main "$@"
