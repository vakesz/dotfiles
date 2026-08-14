#!/usr/bin/env bash
#
# Stow the core dotfiles into $HOME and $XDG_CONFIG_HOME.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"
ADOPT=0
SKIP_PREFLIGHT=0

source "$REPO_ROOT/scripts/lib/common.sh"

usage() {
    cat <<EOF
Usage: ./$SCRIPT_NAME [--adopt] [--skip-preflight]

On macOS, first ensures the Xcode Command Line Tools, Homebrew, and the
Brewfile packages are present. Then stows ./home into \$HOME and ./config
into \$XDG_CONFIG_HOME, and offers to run the matching platform setup script.

Options:
  --adopt           Import existing files into the repo with 'stow --adopt'
  --skip-preflight  Skip the macOS Command Line Tools / Homebrew / Brewfile step
  -h, --help        Show this help text

Examples:
  ./$SCRIPT_NAME
  ./$SCRIPT_NAME --adopt
  ./$SCRIPT_NAME --skip-preflight
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --adopt)
                ADOPT=1
                ;;
            --skip-preflight)
                SKIP_PREFLIGHT=1
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

maybe_run_preflight() {
    if (( SKIP_PREFLIGHT )); then
        info "Skipping preflight"
        return 0
    fi

    [[ "$(detect_platform 2>/dev/null)" == "macos" ]] || return 0

    source "$REPO_ROOT/scripts/lib/macos-preflight.sh"
    run_macos_preflight "$REPO_ROOT/Brewfile"
}

require_stow() {
    command -v stow >/dev/null 2>&1 || {
        error "stow is required"
        info "On macOS it comes from the Brewfile; rerun without --skip-preflight"
        info "On Linux install it with your package manager, e.g. 'sudo apt install stow'"
        exit 1
    }
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

assert_stow_targets_clean() {
    local package target stow_output

    for package in home config; do
        target="$HOME"
        [[ "$package" == "config" ]] && target="$CONFIG_TARGET"

        stow_output="$(stow -n --restow -d "$REPO_ROOT" -t "$target" "$package" 2>&1)" || {
            error "stow found existing files or directories that would conflict with linking"
            if [[ -n "$stow_output" ]]; then
                printf '%s\n' "$stow_output"
            fi
            info "Remove the conflicting files manually, or rerun interactively with: ./$SCRIPT_NAME --adopt"
            exit 1
        }
    done
}

stow_selected_packages() {
    local stow_args=(--restow -d "$REPO_ROOT")

    mkdir -p "$CONFIG_TARGET"
    info "Stowing home/ into $HOME and config/ into $CONFIG_TARGET"

    if (( ADOPT )); then
        stow_args+=(--adopt)
    else
        assert_stow_targets_clean
    fi

    stow "${stow_args[@]}" -t "$HOME" home
    stow "${stow_args[@]}" -t "$CONFIG_TARGET" config

    success "Dotfiles linked"

    if (( ADOPT )) && command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1 && ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null; then
        warn "Existing files were adopted into the repo. Review with: git diff"
    fi
}

maybe_run_platform_setup() {
    local platform=""
    local setup_path=""

    platform="$(detect_platform 2>/dev/null)" || return 0
    setup_path="$REPO_ROOT/scripts/platform/${platform}.sh"

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

    maybe_run_preflight
    ensure_xdg_runtime_directories
    require_stow
    confirm_adopt
    stow_selected_packages
    maybe_run_platform_setup

    success "Bootstrap complete"
}

main "$@"
