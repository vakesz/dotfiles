#!/usr/bin/env bash
#
# Fresh-machine prerequisites for macOS.
#
# These run before any stow work, because bootstrap.sh needs `stow`, `stow`
# comes from Homebrew, and Homebrew needs the Xcode Command Line Tools. Sourced
# by bootstrap.sh and by scripts/platform/macos.sh.
#

# Guard against double-sourcing: bootstrap.sh sources this, then invokes
# macos.sh, which sources it again.
if [[ -n "${_DOTFILES_MACOS_PREFLIGHT_LOADED:-}" ]]; then
    return 0
fi
_DOTFILES_MACOS_PREFLIGHT_LOADED=1

# How long to wait for the GUI Command Line Tools installer, in seconds.
XCODE_CLI_TOOLS_WAIT_TIMEOUT="${XCODE_CLI_TOOLS_WAIT_TIMEOUT:-1800}"

HOMEBREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Set by run_macos_preflight; brewfile_satisfied and install_brewfile act on it.
DOTFILES_BREWFILE=""

xcode_cli_tools_installed() {
    xcode-select -p >/dev/null 2>&1
}

# `xcode-select --install` spawns a GUI installer and returns immediately, so
# callers that depend on git/clang must wait for it to actually finish.
wait_for_xcode_cli_tools() {
    local waited=0

    info "Waiting for the Command Line Tools installer to finish..."
    info "Complete the installer dialog if it is still open."

    while ! xcode_cli_tools_installed; do
        if (( waited >= XCODE_CLI_TOOLS_WAIT_TIMEOUT )); then
            error "Timed out after ${XCODE_CLI_TOOLS_WAIT_TIMEOUT}s waiting for Command Line Tools"
            return 1
        fi
        sleep 5
        (( waited += 5 ))
    done

    success "Xcode Command Line Tools installed"
}

install_xcode_cli_tools() {
    info "Requesting Xcode Command Line Tools installation..."

    # `--install` returns immediately and is non-zero when a dialog is already
    # open, so ignore the exit status and wait for `xcode-select -p` instead.
    xcode-select --install 2>/dev/null || true
    wait_for_xcode_cli_tools
}

ensure_xcode_cli_tools() {
    if xcode_cli_tools_installed; then
        info "Xcode Command Line Tools already installed"
        return 0
    fi

    install_xcode_cli_tools
}

homebrew_installed() {
    command -v brew >/dev/null 2>&1 || [[ -x /opt/homebrew/bin/brew || -x /usr/local/bin/brew ]]
}

# Put brew on PATH for the rest of this script run. A freshly installed
# Homebrew is not on PATH until a new shell picks up the stowed zsh config.
load_homebrew_environment() {
    local brew_path

    command -v brew >/dev/null 2>&1 && return 0

    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_path" ]]; then
            eval "$("$brew_path" shellenv)"
            return 0
        fi
    done

    return 1
}

install_homebrew() {
    info "Installing Homebrew (this asks for your password)..."

    # NONINTERACTIVE skips the installer's "press RETURN" prompt; it still uses
    # sudo, so the password prompt remains.
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALLER_URL")"; then
        error "Homebrew installation failed"
        return 1
    fi

    load_homebrew_environment || {
        error "Homebrew installed but 'brew' is still not on PATH"
        return 1
    }

    success "Homebrew installed"
}

ensure_homebrew() {
    if homebrew_installed; then
        info "Homebrew already installed"
        load_homebrew_environment
        return 0
    fi

    install_homebrew
}

brewfile_satisfied() {
    local brewfile="$DOTFILES_BREWFILE"
    [[ -f "$brewfile" ]] || return 0
    load_homebrew_environment || return 1
    brew bundle check --file "$brewfile" >/dev/null 2>&1
}

install_brewfile() {
    local brewfile="$DOTFILES_BREWFILE"

    [[ -f "$brewfile" ]] || {
        warn "No Brewfile at $brewfile; skipping"
        return 0
    }

    load_homebrew_environment || {
        warn "Homebrew unavailable; skipping Brewfile install"
        return 1
    }

    # mas 7 dropped the `account` subcommand, so there is no way to probe for a
    # signed-in App Store account. Say so up front instead: the mas entries fail
    # without one, while every other entry installs fine.
    if grep -q '^mas ' "$brewfile"; then
        info "Mac App Store entries need a signed-in App Store account to install"
    fi

    info "Installing packages from $brewfile (this takes a while)..."
    brew bundle install --file "$brewfile" || {
        error "Brewfile install failed"
        return 1
    }
    success "Brewfile packages installed"
}

# Everything a clean macOS install needs before bootstrap.sh can stow anything.
# The Brewfile is not optional here: bootstrap needs `stow` from it.
run_macos_preflight() {
    DOTFILES_BREWFILE="$1"

    info "macOS preflight"

    ensure_xcode_cli_tools || return 1
    ensure_homebrew || return 1

    if brewfile_satisfied; then
        info "Brewfile packages already installed"
        return 0
    fi

    install_brewfile || return 1
}
