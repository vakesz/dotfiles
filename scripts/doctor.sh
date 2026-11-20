#!/usr/bin/env bash
# Check that a bootstrapped machine is in the expected state. It only reports,
# never fixes, and exits non-zero on any failure, so it works as a smoke test.
# CI runs it with macOS /bin/bash, so keep it bash 3.2 compatible.
#
#   doctor.sh              every check for this platform
#   doctor.sh --only stow  only the stow links (what CI asserts)

# Deliberately no -e: every check must run so the summary counts all results.
set -uo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/cli-tools.sh"
if is_macos; then
    source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"
    source "$DOTFILES_ROOT/scripts/lib/macos-defaults.sh"
fi

# Required by bootstrap on every platform.
CORE_COMMANDS=(git stow zsh)
# The CLI tools table: installed by the Brewfile on macOS, optional on Linux.
# "a|b" accepts either name, e.g. Debian's fdfind and Fedora's rustup-init.
WORKSTATION_COMMANDS=()
while IFS= read -r command_name; do
    WORKSTATION_COMMANDS+=("$command_name")
done < <(cli_tool_commands)
unset command_name
MACOS_COMMANDS=(brew dockutil gh mas topgrade)

ONLY=""

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
    local script=""

    section "macOS tooling"

    verify "Touch ID for sudo enabled" "Touch ID for sudo not enabled (run scripts/platform/macos.sh)" \
        soft_warn macos_touch_id_sudo_enabled
    verify "Xcode Command Line Tools installed" "Xcode Command Line Tools missing" \
        fail macos_xcode_cli_tools_installed
    verify "full Xcode installation available" "full Xcode installation not available" \
        soft_warn macos_full_xcode_installed
    verify "GitHub CLI authenticated" "GitHub CLI not authenticated (run: gh auth login)" \
        soft_warn quietly gh auth status

    if ! macos_launchd_env_agent_loaded; then
        soft_warn "launchd env agent not installed or not loaded (run scripts/platform/macos.sh)"
    elif ! macos_launchd_env_agent_current; then
        script="$(macos_launchd_env_agent_script)" || script="an unknown script"
        soft_warn "launchd env agent is out of date: it runs $script (run scripts/platform/macos.sh to rewrite it)"
    else
        pass "launchd env agent installed, loaded and current"
    fi
}

# Report every row of lib/macos-defaults.sh that differs from this machine.
check_macos_defaults() {
    local scope domain key type value have clean=1

    section "macOS defaults"

    while IFS='|' read -r scope domain key type value have; do
        soft_warn "$domain $key is $have, expected $value (run scripts/platform/macos.sh)"
        clean=0
    done < <(macos_defaults_drift)

    ((clean)) && pass "all $(macos_defaults_rows | wc -l | tr -d ' ') macOS defaults match"
    return 0
}

# Report only. macos-hardening.sh can fix most of these; SIP can only be
# changed from Recovery, and sharing from System Settings > General > Sharing.
check_macos_security() {
    local label="" check=""

    section "macOS security"

    verify "FileVault enabled" "FileVault is off (run scripts/platform/macos-hardening.sh)" \
        fail macos_filevault_enabled
    verify "System Integrity Protection enabled" "SIP is disabled or customized (re-enable from Recovery: csrutil enable)" \
        fail macos_sip_enabled
    verify "Gatekeeper assessments enabled" "Gatekeeper is off (run scripts/platform/macos-hardening.sh)" \
        fail macos_gatekeeper_enabled
    if macos_auto_login_enabled; then
        fail "Automatic login is on (run scripts/platform/macos-hardening.sh)"
    else
        pass "Automatic login is off"
    fi
    verify "Automatic update checks, downloads and security responses enabled" \
        "Automatic update checks, downloads or security responses are not all on (run scripts/platform/macos-hardening.sh; MDM may manage these)" \
        soft_warn macos_automatic_security_updates_enabled
    if macos_remote_management_active; then
        soft_warn "Remote Management is on (run scripts/platform/macos-hardening.sh, unless IT relies on it)"
    else
        pass "Remote Management is off"
    fi

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

    if macos_firewall_signed_allowlist_off; then
        pass "Firewall asks before signed software accepts connections"
    elif macos_mdm_managed; then
        soft_warn "Firewall allows signed software automatically; this Mac is MDM-managed, so change it in System Settings or ask IT"
    else
        soft_warn "Firewall allows signed software automatically (run scripts/platform/macos-hardening.sh)"
    fi

    for label in File Printer Internet Media; do
        check="macos_$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]')_sharing_enabled"
        if "$check"; then
            soft_warn "$label Sharing is on (turn it off in System Settings > General > Sharing)"
        else
            pass "$label Sharing is off"
        fi
    done
}

# FUSE-T is in the Brewfile. Omnimount itself is optional; when the app is
# present, the CLI on the Homebrew prefix has to be that app's version and
# fuse2fs has to link FUSE-T rather than macFUSE.
check_macos_filesystems() {
    local fuse2fs="" cli="" app_version="" cli_version="" deps=""

    section "Filesystems"

    if ! has_command brew; then
        fail "brew not on PATH; cannot check FUSE-T"
        return 0
    fi

    if ! macos_fuse_t_cask_installed; then
        fail "FUSE-T cask is not installed (brew install --cask fuse-t)"
    else
        pass "FUSE-T cask installed"
        verify "FUSE-T library installed" \
            "FUSE-T cask is listed but $FUSE_T_LIB is missing; reinstall the cask" \
            fail macos_fuse_t_lib_present
    fi

    if macos_macfuse_present; then
        fail "macFUSE is installed alongside FUSE-T; remove macFUSE"
    else
        pass "macFUSE is not installed"
    fi

    if [[ ! -d "$OMNIMOUNT_APP" ]]; then
        soft_warn "Omnimount.app is not installed (optional; run scripts/platform/macos-omnimount.sh)"
        return 0
    fi
    pass "Omnimount.app is installed"

    macos_brew_prefix || {
        fail "Homebrew prefix unavailable; cannot check the Omnimount CLI"
        return 0
    }
    cli="$MACOS_BREW_PREFIX/bin/omnimount"
    if [[ ! -x "$cli" ]]; then
        fail "Omnimount CLI is missing at $cli"
    else
        app_version="$(macos_omnimount_app_version)" || app_version=""
        cli_version="$(macos_omnimount_cli_version "$cli")" || cli_version=""
        if [[ -n "$app_version" && "$cli_version" == "$app_version" ]]; then
            pass "Omnimount CLI ${cli_version} matches the app"
        else
            fail "Omnimount CLI version (${cli_version:-unknown}) does not match the app (${app_version:-unknown})"
        fi
    fi

    if [[ -x "$OMNIMOUNT_APP/Contents/MacOS/fuse2fs" ]]; then
        fuse2fs="$OMNIMOUNT_APP/Contents/MacOS/fuse2fs"
    else
        fuse2fs="$MACOS_BREW_PREFIX/sbin/fuse2fs"
    fi
    if [[ ! -x "$fuse2fs" ]]; then
        fail "fuse2fs is missing"
        return 0
    fi
    deps="$(otool -L "$fuse2fs" 2>/dev/null)" || deps=""
    # libfuse.2.dylib is macFUSE. libfuse-t and libfuse3 are FUSE-T.
    if [[ "$deps" == *"libfuse-t"* || "$deps" == *"libfuse3"* ]] &&
        [[ ! "$deps" =~ libfuse[.][^[:space:]]*|libosxfuse|macfuse ]]; then
        pass "fuse2fs links FUSE-T"
    else
        fail "fuse2fs at $fuse2fs does not link FUSE-T"
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
        soft_warn "Spotlight indexes $count items under $path (run scripts/platform/macos-spotlight.sh; if it's already on the Privacy list, rebuild the index: sudo mdutil -E /System/Volumes/Data)"
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

usage() {
    cat <<EOF
Usage: ${0##*/} [--only stow]

Check that this machine matches what bootstrap.sh produces. Only reports;
exits non-zero when a check fails.

Options:
  --only stow  Run only the stow link checks
  -h, --help   Show this help text
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --only)
                if [[ "${2:-}" != "stow" ]]; then
                    usage >&2
                    exit 2
                fi
                ONLY="stow"
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"

    info "Dotfiles doctor ($DOTFILES_ROOT)"

    set_xdg_environment_defaults

    check_stow_links
    if [[ "$ONLY" == "stow" ]]; then
        print_summary
        return
    fi

    check_xdg_directories
    check_directory_permissions
    check_commands
    check_shell

    if is_macos; then
        check_brewfile
        check_macos_tooling
        check_macos_defaults
        check_macos_filesystems
        check_macos_security
        check_macos_spotlight
    fi

    print_summary
}

main "$@"
