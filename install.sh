#!/usr/bin/env bash
#
# Safe dotfiles installer - symlinks configs with GNU Stow.
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
ADOPT=0

source "$DOTFILES_DIR/scripts/lib/common.sh"

usage() {
    cat <<EOF
Usage: ./$SCRIPT_NAME [--adopt]

Installs symlinks with Stow, then runs the matching platform setup script.

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
    command -v stow >/dev/null 2>&1 || { error "stow is required"; exit 1; }
}

platform_setup_script() {
    local platform=""

    platform="$(current_platform)" || return 1
    printf '%s\n' "$DOTFILES_DIR/scripts/platform/${platform}.sh"
}

remove_stow_junk() {
    find "$DOTFILES_DIR/home" "$DOTFILES_DIR/config" -type f -name '.DS_Store' -delete 2>/dev/null || true
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
    confirm "Continue with stow --adopt?" || { info "Aborted"; exit 0; }
}

run_optional_platform_setup() {
    local setup_script=""

    if ! setup_script="$(platform_setup_script)"; then
        info "No platform setup script for OSTYPE=$OSTYPE; skipping machine setup"
        return 0
    fi

    if [[ ! -x "$setup_script" ]]; then
        warn "Platform setup script is missing or not executable: $setup_script"
        return 0
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        info "Non-interactive shell; skipping optional platform setup"
        return 0
    fi

    info "Starting platform setup: $(basename "$setup_script")"
    "$setup_script"
}

verify_stow_targets_are_clean() {
    if ! stow -n -t "$HOME" home >/dev/null 2>&1 || ! stow -n -t "${XDG_CONFIG_HOME:-$HOME/.config}" config >/dev/null 2>&1; then
        error "stow found existing files or directories that would conflict with safe linking"
        info "Remove the conflicting files manually, or rerun interactively with: ./$SCRIPT_NAME --adopt"
        exit 1
    fi
}

stow_packages() {
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

    info "Creating symlinks with stow..."
    remove_stow_junk

    cd "$DOTFILES_DIR"

    if (( ADOPT )); then
        stow --adopt -t "$HOME" home
        stow --adopt -t "$xdg_config" config
    else
        verify_stow_targets_are_clean
        stow -t "$HOME" home
        stow -t "$xdg_config" config
    fi

    success "Symlinks created"

    if (( ADOPT )) && command -v git >/dev/null 2>&1 && git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if ! git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null; then
            warn "Existing files were adopted into the repo. Review with: git diff"
        fi
    fi
}

main() {
    parse_args "$@"

    info "Dotfiles installer"

    require_stow
    confirm_adopt
    stow_packages
    run_optional_platform_setup

    success "Done!"
}

main "$@"
