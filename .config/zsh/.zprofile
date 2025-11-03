# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Locale Configuration
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# Helper Functions
have() { command -v "$1" >/dev/null 2>&1; }
alias_if_exists() { have "$2" && alias "$1"="$3"; }

# Add Homebrew keg-only package to PATH
add_keg_only() {
    local pkg="$1"
    local bin_path="${2:-bin}"

    if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/$pkg/$bin_path" ]]; then
        export PATH="$HOMEBREW_PREFIX/opt/$pkg/$bin_path:$PATH"

        # Add build flags if library directories exist
        if [[ -d "$HOMEBREW_PREFIX/opt/$pkg/lib" ]]; then
            export LDFLAGS="-L$HOMEBREW_PREFIX/opt/$pkg/lib${LDFLAGS:+ $LDFLAGS}"
        fi
        if [[ -d "$HOMEBREW_PREFIX/opt/$pkg/include" ]]; then
            export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/$pkg/include${CPPFLAGS:+ $CPPFLAGS}"
        fi
        if [[ -d "$HOMEBREW_PREFIX/opt/$pkg/lib/pkgconfig" ]]; then
            export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/$pkg/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
        fi
    fi
}

# Homebrew Setup (Cross-Platform)
if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d ~/.linuxbrew ]]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
fi

# PATH Configuration

# Homebrew keg-only packages
add_keg_only "node@22"
add_keg_only "ruby"
add_keg_only "make" "libexec/gnubin"
add_keg_only "python@3.13"
add_keg_only "llvm"

# NPM/PNPM/Yarn - Keep global installs in XDG directory
export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# Go
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export PATH="$GOPATH/bin:$PATH"

# Rust/Cargo
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Python pipx
export PATH="$XDG_DATA_HOME/pipx/venvs/bin:$PATH"

# Deno
export DENO_INSTALL="$XDG_DATA_HOME/deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Swift Package Manager
export PATH="$HOME/.config/swiftpm/bin:$PATH"

# Python virtual environment helper
alias python='python3.13'
alias python3='python3.13'
alias pip='pip3.13'
alias pip3='pip3.13'
alias py='python3.13'

# Quick virtual environment activation
venv() {
    [ -d .venv ] || py -m venv .venv
    source .venv/bin/activate
}

# Zoxide - smart directory jumping
if have zoxide; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# Neovim (default editor)
if have nvim; then
    alias vi='nvim'
    alias vim='nvim'
    export EDITOR='nvim'
    export VISUAL='nvim'
    export MANPAGER='nvim +Man!'
fi

# Directory Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
