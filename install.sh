#!/usr/bin/env bash
# One-line installer for a fresh Mac or Linux / WSL machine:
#
#   curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
#
# On macOS it installs git via the Command Line Tools; on Linux it installs
# git, stow and zsh with apt-get, dnf, zypper or pacman (needs root or sudo).
# Then it clones the repo and hands off to bootstrap.sh for the rest. It must
# stay self-contained: the repo isn't on disk yet, so nothing in scripts/lib
# is available. Keep it bash 3.2 compatible for macOS /bin/bash.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/vakesz/dotfiles}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
XCODE_CLI_TOOLS_WAIT_TIMEOUT="${XCODE_CLI_TOOLS_WAIT_TIMEOUT:-1800}"

say() {
    printf '\033[34m[INFO]\033[0m %s\n' "$1"
}

die() {
    printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2
    exit 1
}

ensure_git() {
    local waited=0

    # Check xcode-select first: without the tools, the git shim opens the installer.
    xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1 && return 0

    say "Installing the Xcode Command Line Tools for git..."
    xcode-select --install 2>/dev/null || true
    say "Complete the installer dialog; waiting for it to finish..."

    # Poll xcode-select, not git: running the git shim reopens the installer.
    while ! xcode-select -p >/dev/null 2>&1; do
        ((waited >= XCODE_CLI_TOOLS_WAIT_TIMEOUT)) && die "Timed out after ${XCODE_CLI_TOOLS_WAIT_TIMEOUT}s waiting for Command Line Tools"
        sleep 5
        ((waited += 5))
    done

    git --version >/dev/null 2>&1 || die "Command Line Tools installed but git is still unavailable"
    say "Xcode Command Line Tools installed"
}

# Run "$@" as root: directly when already root, else through sudo.
as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Install whichever of git, stow and zsh are missing. Package names match the
# command names on every supported package manager.
ensure_linux_prereqs() {
    local missing="" command_name="" pm=""

    for command_name in git stow zsh; do
        command -v "$command_name" >/dev/null 2>&1 || missing="$missing $command_name"
    done
    [[ -z "$missing" ]] && return 0

    for pm in apt-get dnf zypper pacman ""; do
        [[ -z "$pm" ]] && die "No supported package manager (apt-get, dnf, zypper, pacman) found; install$missing yourself, then rerun"
        command -v "$pm" >/dev/null 2>&1 && break
    done

    if [[ "$(id -u)" -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
        die "sudo is not available; as root, install$missing with $pm, then rerun"
    fi

    say "Installing$missing with $pm..."
    # $missing is a space-separated list of package names; split it on purpose.
    # shellcheck disable=SC2086
    case "$pm" in
        apt-get)
            as_root apt-get update -qq
            # Minimal images lack CA certificates, so the HTTPS clone would fail.
            as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates $missing
            ;;
        dnf) as_root dnf install -y $missing ;;
        zypper) as_root zypper --non-interactive install $missing ;;
        # Never upgrade the whole system from a curl | bash installer; a stale
        # package database is the user's call to sync.
        pacman) as_root pacman -S --needed --noconfirm $missing || die "pacman could not install$missing; run 'sudo pacman -Syu', then rerun" ;;
    esac
}

ensure_repo() {
    local branch=""

    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        [[ -e "$DOTFILES_DIR" ]] && die "$DOTFILES_DIR exists but is not a git repository; move it aside, or set DOTFILES_DIR to another path"
        say "Cloning $DOTFILES_REPO into $DOTFILES_DIR"
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
        return 0
    fi

    branch="$(git -C "$DOTFILES_DIR" branch --show-current)"
    if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
        say "Uncommitted changes in $DOTFILES_DIR; leaving the working tree as-is"
    elif [[ "$branch" != "$DOTFILES_BRANCH" ]]; then
        say "Repo is on '${branch:-detached HEAD}', not $DOTFILES_BRANCH; not switching"
    elif ! git -C "$DOTFILES_DIR" pull --ff-only --quiet origin "$DOTFILES_BRANCH"; then
        say "Could not fast-forward to origin/$DOTFILES_BRANCH; leaving the working tree as-is"
    else
        say "Repo fast-forwarded to origin/$DOTFILES_BRANCH"
    fi
}

main() {
    case "$OSTYPE" in
        darwin* | linux*) ;;
        *) die "Unsupported OS '$OSTYPE'; this installer supports macOS and Linux / WSL" ;;
    esac

    # Under curl | bash, bash reads this script from stdin, so stdin can only be
    # switched to the terminal here, once the whole file has been read. Test that
    # /dev/tty really opens first: without a controlling terminal (CI, docker
    # without -t) it exists but fails to open, and the run stays non-interactive.
    [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null && exec </dev/tty

    say "Dotfiles installer"
    case "$OSTYPE" in
        darwin*) ensure_git ;;
        linux*) ensure_linux_prereqs ;;
    esac
    ensure_repo

    say "Handing off to bootstrap.sh"
    exec "$DOTFILES_DIR/bootstrap.sh" "$@"
}

main "$@"
