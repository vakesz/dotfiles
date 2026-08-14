#!/usr/bin/env bash
#
# One-line installer for a clean macOS machine:
#
#   curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
#
# Installs the Xcode Command Line Tools (for git), clones this repo, and hands
# off to bootstrap.sh, which handles Homebrew, the Brewfile, and stow.
#
# Deliberately self-contained: nothing here may source scripts/lib, because the
# repo is not on disk yet.
#

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/vakesz/dotfiles}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
XCODE_CLI_TOOLS_WAIT_TIMEOUT="${XCODE_CLI_TOOLS_WAIT_TIMEOUT:-1800}"

info() {
    printf '\033[34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\033[32m[OK]\033[0m %s\n' "$1"
}

warn() {
    printf '\033[33m[WARN]\033[0m %s\n' "$1" >&2
}

error() {
    printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2
}

require_macos() {
    [[ "$OSTYPE" == darwin* ]] || {
        error "This installer is macOS only"
        error "On Linux: install git, stow, and zsh, clone the repo, then run ./bootstrap.sh"
        exit 1
    }
}

# When this script is piped into bash, stdin is the pipe rather than the
# terminal, so bootstrap.sh's prompts would read EOF and take the default. Point
# stdin back at the controlling terminal when there is one.
reattach_stdin_to_terminal() {
    if [[ ! -t 0 && -r /dev/tty ]]; then
        exec </dev/tty
    fi
}

ensure_command_line_tools() {
    local waited=0

    if xcode-select -p >/dev/null 2>&1; then
        info "Xcode Command Line Tools already installed"
        return 0
    fi

    info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true

    info "Complete the installer dialog; waiting for it to finish..."
    while ! xcode-select -p >/dev/null 2>&1; do
        if (( waited >= XCODE_CLI_TOOLS_WAIT_TIMEOUT )); then
            error "Timed out after ${XCODE_CLI_TOOLS_WAIT_TIMEOUT}s waiting for Command Line Tools"
            exit 1
        fi
        sleep 5
        (( waited += 5 ))
    done

    success "Xcode Command Line Tools installed"
}

clone_or_update_repo() {
    local current_branch=""

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Repo already present at $DOTFILES_DIR; fetching latest"
        if ! git -C "$DOTFILES_DIR" fetch --quiet origin "$DOTFILES_BRANCH"; then
            warn "Could not fetch origin/$DOTFILES_BRANCH; using the local working tree"
            return 0
        fi

        if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
            warn "Uncommitted changes in $DOTFILES_DIR; leaving the working tree as-is"
            return 0
        fi

        current_branch="$(git -C "$DOTFILES_DIR" branch --show-current)"
        if [[ "$current_branch" != "$DOTFILES_BRANCH" ]]; then
            warn "Repo is on '${current_branch:-detached HEAD}', not $DOTFILES_BRANCH; not switching"
            return 0
        fi

        if git -C "$DOTFILES_DIR" merge --ff-only "origin/${DOTFILES_BRANCH}"; then
            success "Repo fast-forwarded to origin/$DOTFILES_BRANCH"
        else
            warn "Could not fast-forward to origin/$DOTFILES_BRANCH; leaving the working tree as-is"
        fi
        return 0
    fi

    if [[ -e "$DOTFILES_DIR" ]]; then
        error "$DOTFILES_DIR exists but is not a git repository"
        error "Move it aside, or set DOTFILES_DIR to another path"
        exit 1
    fi

    info "Cloning $DOTFILES_REPO into $DOTFILES_DIR"
    git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
    success "Repo cloned"
}

main() {
    require_macos
    reattach_stdin_to_terminal

    info "Dotfiles installer"

    ensure_command_line_tools
    clone_or_update_repo

    info "Handing off to bootstrap.sh"
    exec "$DOTFILES_DIR/bootstrap.sh" "$@"
}

main "$@"
