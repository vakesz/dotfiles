#!/usr/bin/env bash
# Link the dotfiles into $HOME and the XDG directories with stow.

set -euo pipefail

# shellcheck source=scripts/lib/paths.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/lib/paths.sh"
# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/platform.sh
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
}

maybe_run_preflight() {
    if ((SKIP_PREFLIGHT)); then
        info "Skipping preflight"
        return 0
    fi

    is_macos || return 0

    # shellcheck source=scripts/lib/macos-preflight.sh
    source "$DOTFILES_ROOT/scripts/lib/macos-preflight.sh"
    run_macos_preflight "$DOTFILES_BREWFILE"
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
    if ((ADOPT == 0)); then
        return 0
    fi

    if ! is_interactive; then
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

# Remove links left by older layouts that would block or outlive the current
# packages. Each removal only matches the exact shape an older bootstrap made.
# Safe to delete once every machine has rerun bootstrap.
remove_legacy_links() {
    local legacy_gradle="$GRADLE_USER_HOME/gradle.properties" path=""

    # gradle.properties used to live in config/ and was linked into
    # $GRADLE_USER_HOME with an absolute `ln -sfn`. stow can't replace that
    # link, so the data/ package would conflict.
    if [[ -L "$legacy_gradle" && "$(readlink "$legacy_gradle")" == "$XDG_CONFIG_HOME/gradle/gradle.properties" ]]; then
        rm -f -- "$legacy_gradle"
        info "Removed legacy link $legacy_gradle"
    fi

    # Restowing config/ leaves links to files that moved out of it dangling.
    for path in gradle/gradle.properties linearmouse/linearmouse.json; do
        remove_dangling_repo_link "$XDG_CONFIG_HOME/$path" "config/$path"
    done
}

# Remove $1 if it is a dangling link to $DOTFILES_ROOT/$2, then its parent
# directory if that is now empty.
remove_dangling_repo_link() {
    local link="$1" repo_path="$2" target="" existing="" rest=""

    [[ -L "$link" && ! -e "$link" ]] || return 0

    # stow links are relative to the link's directory.
    target="$(readlink "$link")"
    [[ "$target" == /* ]] || target="${link%/*}/$target"

    # The file and maybe its directories are gone, so resolve the deepest
    # directory that still exists and append the rest.
    existing="${target%/*}"
    rest="${target##*/}"
    while [[ -n "$existing" && ! -d "$existing" ]]; do
        rest="${existing##*/}/$rest"
        existing="${existing%/*}"
    done
    # A .. below a missing directory can't be resolved; leave such links alone.
    [[ "/$rest/" != */../* ]] || return 0
    existing="$(cd "${existing:-/}" && pwd -P)" || return 0

    [[ "$existing/$rest" == "$DOTFILES_ROOT/$repo_path" ]] || return 0

    rm -f -- "$link"
    rmdir -- "${link%/*}" 2>/dev/null || true
    info "Removed stale link $link"
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

    while IFS=$'\t' read -r package target; do
        mkdir -p "$target"
        info "Stowing $package/ into $target"
        stow "${stow_args[@]}" -t "$target" "$package"
    done < <(stow_package_targets)

    success "Dotfiles linked"

    if ((ADOPT)) && command -v git >/dev/null 2>&1 && git -C "$DOTFILES_ROOT" rev-parse --git-dir >/dev/null 2>&1 && ! git -C "$DOTFILES_ROOT" diff --quiet 2>/dev/null; then
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
    remove_legacy_links
    stow_packages
    maybe_run_platform_setup

    success "Bootstrap complete"
}

main "$@"
