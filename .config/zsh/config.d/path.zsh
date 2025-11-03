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

if [[ "$OS_TYPE" == "macos" ]]; then
  # macOS Homebrew initialization
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # macOS Homebrew keg-only packages
  add_keg_only "curl"

  # Dynamically detect latest installed Node version
  if [[ -n "$HOMEBREW_PREFIX" ]] && [[ -d "$HOMEBREW_PREFIX/opt" ]]; then
    local node_keg=$(ls -d "$HOMEBREW_PREFIX/opt/node@"* 2>/dev/null | sort -V | tail -1)
    [[ -n "$node_keg" ]] && add_keg_only "$(basename "$node_keg")"

    local python_keg=$(ls -d "$HOMEBREW_PREFIX/opt/python@"* 2>/dev/null | sort -V | tail -1)
    [[ -n "$python_keg" ]] && add_keg_only "$(basename "$python_keg")"
  fi

  add_keg_only "llvm"
  add_keg_only "ruby"
  add_keg_only "make" "libexec/gnubin"

  # Xcode command line tools
  if [[ -d "/Applications/Xcode.app/Contents/Developer/usr/bin" ]]; then
    export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"
  fi

elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  # Linux/WSL Rust/Cargo
  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
  fi
  export PATH="$HOME/.cargo/bin:$PATH"

  # Local binaries (oh-my-posh, custom scripts, etc.)
  export PATH="$HOME/.local/bin:$PATH"

  # Python user packages
  export PATH="$HOME/.local/share/python/bin:$PATH"

  # Snap packages (Ubuntu/Debian)
  if [[ -d "/snap/bin" ]]; then
    export PATH="/snap/bin:$PATH"
  fi
fi

# ----------------------------------------------------------------------------
# Cross-Platform Development Tools
# ----------------------------------------------------------------------------

# Go
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export PATH="$GOPATH/bin:$PATH"

# Rust/Cargo
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Node.js - npm/pnpm
export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm"
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PNPM_HOME:$PATH"

# Python pipx
export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/pipx/venvs/bin:$PATH"

# Deno
export DENO_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Swift Package Manager
export PATH="$HOME/.config/swiftpm/bin:$PATH"
