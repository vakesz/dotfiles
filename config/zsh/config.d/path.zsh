# shellcheck shell=bash disable=SC2168
# PATH Configuration

add_keg_only() {
  local pkg="$1" bin="${2:-bin}"
  [[ -d "$HOMEBREW_PREFIX/opt/$pkg/$bin" ]] && export PATH="$HOMEBREW_PREFIX/opt/$pkg/$bin:$PATH"
}

if [[ "$OS_TYPE" == "macos" ]]; then
  # Homebrew (cached for speed)
  brew_path=""
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    brew_path="/opt/homebrew/bin/brew"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    brew_path="/usr/local/bin/brew"
  fi

  if [[ -n "$brew_path" ]]; then
    local brew_cache="$XDG_CACHE_HOME/zsh/brew_shellenv.zsh"
    if [[ ! -f "$brew_cache" || "$brew_path" -nt "$brew_cache" ]]; then
      mkdir -p "${brew_cache:h}"
      "$brew_path" shellenv > "$brew_cache" 2>/dev/null
    fi
    source "$brew_cache"
  fi

  add_keg_only "curl"
  add_keg_only "ruby"
  add_keg_only "make" "libexec/gnubin"

elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  if [[ -d "/snap/bin" ]]; then
    export PATH="/snap/bin:$PATH"
  fi

  # NVM (lazy-loaded)
  export NVM_DIR="${XDG_DATA_HOME}/nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _nvm_load() {
      unfunction nvm node npm npx 2>/dev/null
      source "$NVM_DIR/nvm.sh"
      [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    }
    nvm() { _nvm_load && nvm "$@"; }
    node() { _nvm_load && node "$@"; }
    npm() { _nvm_load && npm "$@"; }
    npx() { _nvm_load && npx "$@"; }
  fi
fi

# Development tools (XDG paths)

export GOPATH="${XDG_DATA_HOME}/go"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod"
[[ -d "$GOPATH/bin" ]] && export PATH="$GOPATH/bin:$PATH"

export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
[[ -d "$CARGO_HOME/bin" ]] && export PATH="$CARGO_HOME/bin:$PATH"

export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export PNPM_HOME="${XDG_DATA_HOME}/pnpm"
[[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"

export UV_CACHE_DIR="${XDG_CACHE_HOME}/uv"
export UV_TOOL_DIR="${XDG_DATA_HOME}/uv/tools"
export UV_TOOL_BIN_DIR="${XDG_DATA_HOME}/uv/bin"
export UV_PYTHON_INSTALL_DIR="${XDG_DATA_HOME}/uv/python"
[[ -d "$UV_TOOL_BIN_DIR" ]] && export PATH="${UV_TOOL_BIN_DIR}:$PATH"

export BUN_INSTALL="${XDG_DATA_HOME}/bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

export SWIFTPM_HOME="${XDG_DATA_HOME}/swiftpm"
[[ -d "$SWIFTPM_HOME/bin" ]] && export PATH="$SWIFTPM_HOME/bin:$PATH"
