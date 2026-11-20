#!/usr/bin/env bash
# Everything a fresh Mac needs before bootstrap.sh can stow. This runs before
# Homebrew (and its bash 5) exists, so keep it bash 3.2 compatible.

[[ -n "${__DOTFILES_MACOS_PREFLIGHT_LOADED:-}" ]] && return 0
__DOTFILES_MACOS_PREFLIGHT_LOADED=1

source "${BASH_SOURCE[0]%/*}/ui.sh"
source "${BASH_SOURCE[0]%/*}/macos-state.sh"

XCODE_CLI_TOOLS_WAIT_TIMEOUT="${XCODE_CLI_TOOLS_WAIT_TIMEOUT:-1800}"
readonly XCODE_CLI_TOOLS_WAIT_TIMEOUT
HOMEBREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly HOMEBREW_INSTALLER_URL

# Install the Xcode Command Line Tools via the GUI installer if missing.
ensure_xcode_cli_tools() {
    local waited=0

    if macos_xcode_cli_tools_installed; then
        info "Xcode Command Line Tools already installed"
        return 0
    fi

    info "Requesting Xcode Command Line Tools installation..."
    # --install opens a GUI installer and returns at once (non-zero if a dialog
    # is already open), so wait on `xcode-select -p` instead.
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

# A fresh Homebrew isn't on PATH until a new shell loads the stowed zsh config,
# so add it for the rest of this run.
load_homebrew_environment() {
    local brew_path

    has_command brew && return 0

    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_path" ]]; then
            # Output comes from the Homebrew binary itself, not user input.
            eval "$("$brew_path" shellenv)"
            return 0
        fi
    done

    return 1
}

# Install Homebrew if the shellenv loader above found nothing.
ensure_homebrew() {
    local installer="" status=0

    if load_homebrew_environment; then
        info "Homebrew already installed"
        return 0
    fi

    info "Installing Homebrew (this asks for your password)..."

    # NONINTERACTIVE skips the "press RETURN" prompt, but it also makes the
    # installer call `sudo -n`, which aborts unless sudo is already cached.
    sudo -v || {
        error "Homebrew installation needs sudo"
        return 1
    }

    # Download to a file first: `bash -c "$(curl ...)"` runs an empty script,
    # and reports success, when the download fails.
    installer="$(mktemp "${TMPDIR:-/tmp}/homebrew-install.XXXXXX")" || {
        error "Could not create a temporary file for the Homebrew installer"
        return 1
    }
    # shellcheck disable=SC2064 # expand the path now; the trap may run after return
    trap "rm -f -- $(printf '%q' "$installer")" EXIT

    if ! curl -fsSL --proto '=https' -o "$installer" "$HOMEBREW_INSTALLER_URL" || [[ ! -s "$installer" ]]; then
        error "Could not download the Homebrew installer from $HOMEBREW_INSTALLER_URL"
        status=1
    elif ! NONINTERACTIVE=1 /bin/bash "$installer"; then
        error "Homebrew installation failed"
        status=1
    fi
    rm -f -- "$installer"
    trap - EXIT
    ((status == 0)) || return 1

    load_homebrew_environment || {
        error "Homebrew installed but 'brew' is still not on PATH"
        return 1
    }

    success "Homebrew installed"
}

# Install every Brewfile entry unless everything is already satisfied.
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

    # mas 7 removed `account`, so App Store sign-in can't be checked. Mention it
    # up front instead.
    if grep -q '^mas ' "$brewfile"; then
        info "Mac App Store entries need a signed-in App Store account to install"
    fi

    info "Installing packages from $brewfile (this takes a while)..."
    if ! brew bundle install --file "$brewfile"; then
        # One bad entry (often a mas app without an App Store sign-in) should
        # not stop bootstrap from linking the dotfiles.
        if has_command stow; then
            warn "Some Brewfile entries failed to install; continuing because stow is available"
            info "Fix them later with: brew bundle install --file $brewfile"
            return 0
        fi
        error "Brewfile install failed, and stow is not installed yet"
        return 1
    fi
    success "Brewfile packages installed"
}

# Bootstrap needs stow from the Brewfile. ensure_brewfile only fails when stow
# is still missing.
run_macos_preflight() {
    local brewfile="$1"

    info "macOS preflight"

    ensure_xcode_cli_tools || return 1
    ensure_homebrew || return 1
    ensure_brewfile "$brewfile" || return 1
}
