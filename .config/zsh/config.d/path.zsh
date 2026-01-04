# shellcheck shell=sh
# ============================================================================
# PATH Configuration
# ============================================================================
# All PATH modifications and package manager initialization

# ----------------------------------------------------------------------------
# Helper: Add Homebrew keg-only packages to PATH
# ----------------------------------------------------------------------------
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

# ----------------------------------------------------------------------------
# Platform-Specific PATH Setup
# ----------------------------------------------------------------------------

# shellcheck shell=sh

if [[ "$OS_TYPE" == "macos" ]]; then
  # macOS Homebrew initialization (cached for speed)
  local brew_path
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    brew_path="/opt/homebrew/bin/brew"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    brew_path="/usr/local/bin/brew"
  fi

  if [[ -n "$brew_path" ]]; then
    local brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/brew_shellenv.zsh"
    if [[ ! -f "$brew_cache" || "$brew_cache" -ot "$brew_path" ]]; then
      mkdir -p "${brew_cache:h}"
      "$brew_path" shellenv > "$brew_cache" 2>/dev/null
    fi
    source "$brew_cache"
  fi

  # macOS Homebrew keg-only packages
  add_keg_only "curl"

  # Python 3.13 (explicit version to avoid 3.14 compatibility issues)
  add_keg_only "python@3.13"

  add_keg_only "llvm"
  add_keg_only "ruby"
  add_keg_only "make" "libexec/gnubin"
  add_keg_only "node"

  # Xcode command line tools
  if [[ -d "/Applications/Xcode.app/Contents/Developer/usr/bin" ]]; then
    export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"
  fi

elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  # Python user packages
  export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/python/bin:$PATH"

  # Snap packages (Ubuntu/Debian)
  if [[ -d "/snap/bin" ]]; then
    export PATH="/snap/bin:$PATH"
  fi
fi

# ----------------------------------------------------------------------------
# Cross-Platform Development Tools (XDG-Compliant)
# ----------------------------------------------------------------------------

# Go
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export GOBIN="${GOBIN:-$GOPATH/bin}"
export PATH="$GOBIN:$PATH"

# Rust/Cargo
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Rustup (Linux only - macOS uses brew rust)
if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
fi

# Node.js - npm config (XDG-compliant, without NPM_CONFIG_PREFIX)
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/npm"

# Node.js - pnpm (XDG-compliant)
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Python pipx
export PIPX_HOME="${PIPX_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pipx}"
export PIPX_BIN_DIR="${PIPX_BIN_DIR:-$PIPX_HOME/bin}"
export PATH="$PIPX_BIN_DIR:$PATH"

# Deno (Linux only - macOS uses brew deno)
if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  export DENO_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

# Swift Package Manager (XDG compliant)
export SWIFTPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/swiftpm"
export PATH="$SWIFTPM_HOME/bin:$PATH"

# tldr / tealdeer (XDG compliant)
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tealdeer"
