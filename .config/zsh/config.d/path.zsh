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

  # Dynamically detect latest installed Python version (optimized)
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    local python_keg
    for python_keg in "$HOMEBREW_PREFIX/opt"/python@3.*(N-/On[1]); do
      [[ -d "$python_keg" ]] && add_keg_only "${python_keg:t}" && break
    done
  fi

  add_keg_only "llvm"
  add_keg_only "ruby"
  add_keg_only "make" "libexec/gnubin"

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

# Rust/Cargo + Rustup
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
export PATH="$CARGO_HOME/bin:$PATH"

# Node.js - nvm (lazy-loaded for fast startup)
export NVM_DIR="${NVM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # Resolve nvm alias chain to get actual version (e.g., lts/* → lts/krypton → v24.x.x)
  __resolve_nvm_alias() {
    local alias_name="$1"
    local alias_file="$NVM_DIR/alias/$alias_name"
    local max_depth=10
    local depth=0

    while [[ -f "$alias_file" ]] && (( depth++ < max_depth )); do
      alias_name=$(<"$alias_file")
      alias_file="$NVM_DIR/alias/$alias_name"
    done

    echo "$alias_name"
  }

  # Add default node to PATH without loading nvm
  if [[ -f "$NVM_DIR/alias/default" ]]; then
    local default_version
    default_version=$(__resolve_nvm_alias "default")
    local node_path="$NVM_DIR/versions/node/$default_version/bin"
    [[ -d "$node_path" ]] && export PATH="$node_path:$PATH"
  fi

  # Clean up helper function
  unset -f __resolve_nvm_alias

  # Lazy-load nvm on first use
  __load_nvm() {
    unset -f nvm node npm npx yarn pnpm 2>/dev/null
    source "$NVM_DIR/nvm.sh"
  }

  nvm() { __load_nvm && nvm "$@"; }
  node() { __load_nvm && node "$@"; }
  npm() { __load_nvm && npm "$@"; }
  npx() { __load_nvm && npx "$@"; }
  yarn() { __load_nvm && yarn "$@"; }
  pnpm() { __load_nvm && pnpm "$@"; }
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

# Deno
export DENO_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Swift Package Manager (XDG compliant)
export SWIFTPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/swiftpm"
export PATH="$SWIFTPM_HOME/bin:$PATH"

# Yarn (XDG compliant)
export YARN_CACHE_FOLDER="${XDG_CACHE_HOME:-$HOME/.cache}/yarn"
export YARN_GLOBAL_FOLDER="${XDG_DATA_HOME:-$HOME/.local/share}/yarn"

# tldr / tealdeer (XDG compliant)
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tealdeer"
