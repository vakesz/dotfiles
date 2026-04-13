#!/usr/bin/env bash
#
# Stow the core dotfiles into $HOME and $XDG_CONFIG_HOME.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
ADOPT=0

source "$REPO_ROOT/scripts/lib/common.sh"

usage() {
    cat <<EOF
Usage: ./$SCRIPT_NAME [--adopt]

Stows ./home into \$HOME and ./config into \$XDG_CONFIG_HOME.
Then optionally offers to run the matching platform setup script.

Options:
  --adopt     Import existing files into the repo with 'stow --adopt'
  -h, --help  Show this help text

Examples:
  ./$SCRIPT_NAME
  ./$SCRIPT_NAME --adopt
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --adopt)
                ADOPT=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

require_stow() {
    command -v stow >/dev/null 2>&1 || {
        error "stow is required"
        exit 1
    }
}

xdg_config_target() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

platform_setup_path() {
    local platform=""

    platform="$(detect_platform)" || return 1
    printf '%s\n' "$REPO_ROOT/scripts/platform/${platform}.sh"
}

confirm_adopt() {
    if (( ADOPT == 0 )); then
        return 0
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        error "--adopt requires an interactive terminal"
        info "Rerun interactively: ./$SCRIPT_NAME --adopt"
        exit 1
    fi

    warn "stow --adopt will overwrite repo files with any existing system files."
    warn "Review changes afterward with: git diff"
    confirm "Continue with stow --adopt?" || {
        info "Aborted"
        exit 0
    }
}

ensure_stow_targets_exist() {
    local config_target=""

    config_target="$(xdg_config_target)"
    mkdir -p "$HOME" "$config_target"
}

assert_stow_targets_clean() {
    local config_target=""

    config_target="$(xdg_config_target)"

    if ! stow -n -d "$REPO_ROOT" -t "$HOME" home >/dev/null 2>&1 || ! stow -n -d "$REPO_ROOT" -t "$config_target" config >/dev/null 2>&1; then
        error "stow found existing files or directories that would conflict with linking"
        info "Remove the conflicting files manually, or rerun interactively with: ./$SCRIPT_NAME --adopt"
        exit 1
    fi
}

stow_selected_packages() {
    local config_target=""

    config_target="$(xdg_config_target)"

    ensure_stow_targets_exist
    info "Stowing home/ into $HOME and config/ into $config_target"

    if (( ADOPT )); then
        stow --adopt -d "$REPO_ROOT" -t "$HOME" home
        stow --adopt -d "$REPO_ROOT" -t "$config_target" config
    else
        assert_stow_targets_clean
        stow -d "$REPO_ROOT" -t "$HOME" home
        stow -d "$REPO_ROOT" -t "$config_target" config
    fi

    success "Dotfiles linked"

    if (( ADOPT )) && command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null; then
            warn "Existing files were adopted into the repo. Review with: git diff"
        fi
    fi
}

maybe_run_platform_setup() {
    local setup_path=""

    if ! setup_path="$(platform_setup_path 2>/dev/null)"; then
        return 0
    fi

    if [[ ! -x "$setup_path" ]]; then
        warn "Platform setup script is missing or not executable: $setup_path"
        return 0
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        info "Non-interactive shell; skipping optional platform setup prompt"
        info "Run it later with: ./${setup_path#"$REPO_ROOT/"}"
        return 0
    fi

    if confirm "Run optional $(basename "$setup_path") setup now?"; then
        "$setup_path"
    else
        info "Skipping platform setup for now"
    fi
}

main() {
    parse_args "$@"

    info "Dotfiles bootstrap"

    require_stow
    confirm_adopt
    stow_selected_packages
    maybe_run_platform_setup

    success "Done!"
}

main "$@"
