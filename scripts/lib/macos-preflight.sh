#!/usr/bin/env bash
# Everything a clean macOS install needs before bootstrap.sh can stow anything.

# shellcheck source=scripts/lib/ui.sh
source "${BASH_SOURCE[0]%/*}/ui.sh"
# shellcheck source=scripts/lib/macos-state.sh
source "${BASH_SOURCE[0]%/*}/macos-state.sh"

XCODE_CLI_TOOLS_WAIT_TIMEOUT="${XCODE_CLI_TOOLS_WAIT_TIMEOUT:-1800}"
HOMEBREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

ensure_xcode_cli_tools() {
    local waited=0

    if macos_xcode_cli_tools_installed; then
        info "Xcode Command Line Tools already installed"
        return 0
    fi

    info "Requesting Xcode Command Line Tools installation..."
    # `--install` spawns a GUI installer, returns immediately and is non-zero
    # when a dialog is already open, so poll `xcode-select -p` instead.
    xcode-select --install 2>/dev/null || true

    info "Waiting for the Command Line Tools installer to finish..."
    info "Complete the installer dialog if it is still open."
    while ! macos_xcode_cli_tools_installed; do
        if ((waited >= XCODE_CLI_TOOLS_WAIT_TIMEOUT)); then
            error "Timed out after ${XCODE_CLI_TOOLS_WAIT_TIMEOUT}s waiting for Command Line Tools"
            return 1
        fi
        sleep 5
        ((waited += 5))
    done

    success "Xcode Command Line Tools installed"
}

# A freshly installed Homebrew is not on PATH until a new shell picks up the
# stowed zsh config, so put it there for the rest of this run.
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

ensure_homebrew() {
    if load_homebrew_environment; then
        info "Homebrew already installed"
        return 0
    fi

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

ensure_brewfile() {
    local brewfile="$1"

    [[ -f "$brewfile" ]] || {
        warn "No Brewfile at $brewfile; skipping"
        return 0
    }

    load_homebrew_environment || {
        warn "Homebrew unavailable; skipping Brewfile install"
        return 1
    }

    if brew bundle check --file "$brewfile" >/dev/null 2>&1; then
        info "Brewfile packages already installed"
        return 0
    fi

    # mas 7 dropped the `account` subcommand, so a signed-in App Store account
    # cannot be probed for; say so up front instead.
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

# The Brewfile is not optional here: bootstrap needs `stow` from it.
run_macos_preflight() {
    local brewfile="$1"

    info "macOS preflight"

    ensure_xcode_cli_tools || return 1
    ensure_homebrew || return 1
    ensure_brewfile "$brewfile" || return 1
}
