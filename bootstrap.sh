#!/usr/bin/env bash
# Link the dotfiles into $HOME and the XDG directories with stow. On a fresh
# Mac this runs under /bin/bash before Homebrew (and its bash 5) exists, so keep
# it, and the scripts/lib files it sources, bash 3.2 compatible.

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"

SCRIPT_NAME="${0##*/}"
ADOPT=0
SKIP_PREFLIGHT=0

# --no-folding links files individually so a later *.local.zsh lands in
# $XDG_CONFIG_HOME, never inside the repo working tree. The packages have no
# .stow-local-ignore on purpose: a local ignore file replaces stow's built-in
# defaults (README, .git, ...), while --ignore adds to them.
# stow anchors each --ignore at the end of the package-relative path only, so
# (^|/) pins a pattern to the start of a file name and ^ to the package root.
STOW_ARGS=(
    --no-folding
    -d "$DOTFILES_ROOT"
    --ignore='(^|/)\.DS_Store'
    --ignore='(^|/)\._[^/]*'
    --ignore='(^|/)\.AppleDouble'
    --ignore='(^|/)\.LSOverride'
    --ignore='\.sw[op]'
    --ignore='~'
    --ignore='(^|/)#[^/]*#'
    # Machine-local overrides, in case one is ever copied into the repo.
    --ignore='(^|/)[^/]+\.local'
    --ignore='^zsh/rc\.d/[^/]+\.local\.zsh'
)

usage() {
    cat <<EOF
Usage: ./$SCRIPT_NAME [--adopt] [--skip-preflight]

On macOS, first ensures the Xcode Command Line Tools, Homebrew, and the
Brewfile packages are present. Then stows ./home into \$HOME, ./config (and
./config-macos on macOS) into \$XDG_CONFIG_HOME and ./data into
\$XDG_DATA_HOME, and offers to run the matching platform setup script.

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
            -h | --help)
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

    # Check before preflight, which can take a long time on a fresh Mac.
    if ((ADOPT)) && ! is_interactive; then
        error "--adopt requires an interactive terminal"
        info "Rerun interactively: ./$SCRIPT_NAME --adopt"
        exit 1
    fi
}

maybe_run_preflight() {
    if ((SKIP_PREFLIGHT)); then
        info "Skipping preflight"
        return 0
    fi

    is_macos || return 0

    source "$DOTFILES_ROOT/scripts/lib/macos-preflight.sh"
    run_macos_preflight "$DOTFILES_BREWFILE"
}

require_stow() {
    has_command stow || {
        error "stow is required"
        info "On macOS it comes from the Brewfile; rerun without --skip-preflight"
        info "On Linux install it with your package manager, e.g. 'sudo apt install stow'"
        exit 1
    }
}

confirm_adopt() {
    if ((ADOPT == 0)); then
        return 0
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

    while IFS=$'\t' read -r package target; do
        stow_output="$(stow -n --restow "${STOW_ARGS[@]}" -t "$target" "$package" 2>&1)" || {
            error "stow found existing files or directories that would conflict with linking $package/"
            if [[ -n "$stow_output" ]]; then
                printf '%s\n' "$stow_output"
            fi
            info "Remove the conflicting files manually, or rerun interactively with: ./$SCRIPT_NAME --adopt"
            exit 1
        }
    done < <(stow_package_targets)
}

stow_packages() {
    local package target stow_args=(--restow "${STOW_ARGS[@]}")

    if ((ADOPT)); then
        stow_args+=(--adopt)
    else
        assert_stow_targets_clean
    fi

    # ensure_xdg_runtime_directories already created every target.
    while IFS=$'\t' read -r package target; do
        info "Stowing $package/ into $target"
        stow "${stow_args[@]}" -t "$target" "$package"
    done < <(stow_package_targets)

    success "Dotfiles linked"

    if ((ADOPT)) && has_command git && git -C "$DOTFILES_ROOT" rev-parse --git-dir >/dev/null 2>&1 && ! git -C "$DOTFILES_ROOT" diff --quiet 2>/dev/null; then
        warn "Existing files were adopted into the repo. Review with: git diff"
    fi
}

maybe_run_platform_setup() {
    local platform="" setup_path=""

    platform="$(detect_platform 2>/dev/null)" || return 0
    setup_path="$DOTFILES_ROOT/scripts/platform/${platform}.sh"

    if [[ ! -x "$setup_path" ]]; then
        warn "Platform setup script is missing or not executable: $setup_path"
        return 0
    fi

    if ! is_interactive; then
        info "Non-interactive shell; skipping optional platform setup prompt"
        info "Run it later with: ./${setup_path#"$DOTFILES_ROOT/"}"
        return 0
    fi

    if confirm "Run optional ${setup_path##*/} setup now?"; then
        "$setup_path" || warn "Platform setup did not complete"
    else
        info "Skipping platform setup for now"
    fi
}

main() {
    parse_args "$@"
    set_xdg_environment_defaults

    info "Dotfiles bootstrap"

    maybe_run_preflight
    ensure_xdg_runtime_directories
    require_stow
    confirm_adopt
    stow_packages
    maybe_run_platform_setup

    success "Bootstrap complete"
}

main "$@"
