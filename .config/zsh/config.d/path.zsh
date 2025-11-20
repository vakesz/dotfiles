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
    python_keg=$(ls -d "$HOMEBREW_PREFIX/opt/python@"* 2>/dev/null | sort -V | tail -1)
    [[ -n "$python_keg" ]] && add_keg_only "$(basename "$python_keg")"
  fi

  add_keg_only "llvm"
  add_keg_only "ruby"
  add_keg_only "make" "libexec/gnubin"

  # Xcode command line tools
  if [[ -d "/Applications/Xcode.app/Contents/Developer/usr/bin" ]]; then
    export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"
  fi

  # Local binaries (claude, custom scripts, etc.)
  export PATH="$HOME/.local/bin:$PATH"

elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  # Linux/WSL Rust/Cargo (XDG compliant)
  export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
  export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
  export PATH="$CARGO_HOME/bin:$PATH"

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
# Cross-Platform Development Tools (XDG-Compliant)
# ----------------------------------------------------------------------------

# Go
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export PATH="$GOPATH/bin:$PATH"
export GOBIN="${GOBIN:-$GOPATH/bin}"
export PATH="$GOBIN:$PATH"

# Rust/Cargo + Rustup
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
export PATH="$CARGO_HOME/bin:$PATH"

# Node.js - nvm (XDG-compliant)
# NVM is incompatible with NPM_CONFIG_PREFIX, so we don't set it
# NVM manages npm in $NVM_DIR/versions/node/*/bin
export NVM_DIR="${NVM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh" --no-use

  # Auto-load default node version if set
  # This is faster than 'nvm use default' and avoids the overhead
  if [[ -f "$NVM_DIR/alias/default" ]] && [[ -d "$NVM_DIR/versions/node" ]]; then
    local default_version
    default_version=$(cat "$NVM_DIR/alias/default" 2>/dev/null)

    # Only proceed if we successfully read the default version
    if [[ -n "$default_version" ]]; then
      local node_path="$NVM_DIR/versions/node/$default_version/bin"

      # Resolve LTS aliases to actual version
      if [[ "$default_version" == lts/* ]]; then
        local resolved_version
        resolved_version=$(nvm version "$default_version" 2>/dev/null)
        if [[ -n "$resolved_version" && "$resolved_version" != "N/A" ]]; then
          node_path="$NVM_DIR/versions/node/$resolved_version/bin"
        fi
      fi

      # Add to PATH only if the bin directory actually exists
      if [[ -d "$node_path" ]]; then
        export PATH="$node_path:$PATH"
      fi
    fi
  fi
fi

# Node.js - npm config (XDG-compliant, without NPM_CONFIG_PREFIX)
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/npm"

# Node.js - pnpm (XDG-compliant)
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Python pipx
export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/pipx/venvs/bin:$PATH"

# Deno
export DENO_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Swift Package Manager (XDG compliant)
export SWIFTPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/swiftpm"
export PATH="$SWIFTPM_HOME/bin:$PATH"

# Docker (XDG compliant)
export DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker"

# tldr / tealdeer (XDG compliant)
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tealdeer"
