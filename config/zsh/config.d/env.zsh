# ============================================================================
# Environment Variables
# ============================================================================
# All environment variable exports (non-PATH)

# ----------------------------------------------------------------------------
# Locale
# ----------------------------------------------------------------------------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# ----------------------------------------------------------------------------
# Editor
# ----------------------------------------------------------------------------
if have nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  export MANPAGER='nvim +Man!'
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

# ----------------------------------------------------------------------------
# GPG
# ----------------------------------------------------------------------------
# Always set GPG_TTY to current terminal
export GPG_TTY=$(tty 2>/dev/null || echo "not a tty")

# ----------------------------------------------------------------------------
# Development Tools (XDG-Compliant)
# ----------------------------------------------------------------------------

# Less: Better default options
export LESS='-R -i -M -W -x4 -F -X'
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"

# Ripgrep config
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"

# Wget config (use XDG location for wgetrc)
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"

# Curl config
export CURL_HOME="${XDG_CONFIG_HOME}/curl"

# Python: Use XDG for pycache (Python 3.8+)
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"

# UV (Python package manager)
export UV_CACHE_DIR="${XDG_CACHE_HOME}/uv"
export UV_TOOL_DIR="${XDG_DATA_HOME}/uv/tools"
export UV_TOOL_BIN_DIR="${XDG_DATA_HOME}/uv/bin"
export UV_PYTHON_INSTALL_DIR="${XDG_DATA_HOME}/uv/python"

# Elixir Mix: Enable XDG support
export MIX_XDG=1

# ----------------------------------------------------------------------------
# Programming Language Environments (XDG-Compliant)
# ----------------------------------------------------------------------------

# Go
export GOPATH="${XDG_DATA_HOME}/go"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod"

# Rust
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"

# Ruby
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"

# Node.js / Deno / Bun
export NODE_REPL_HISTORY="${XDG_STATE_HOME}/node_repl_history"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export DENO_INSTALL_ROOT="${XDG_DATA_HOME}/deno"
export BUN_INSTALL="${XDG_DATA_HOME}/bun"

# ----------------------------------------------------------------------------
# Application-Specific XDG Compliance
# ----------------------------------------------------------------------------
# These prevent individual apps from polluting HOME

# Node.js version managers
export N_PREFIX="${XDG_DATA_HOME}/node"
# NVM_DIR is set in path.zsh where nvm is initialized

# Ruby bundler
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}/bundle"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"

# GnuPG
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"

# Git Credential Manager (cross-platform)
export GCM_CREDENTIAL_CACHE_DIR="${XDG_CACHE_HOME}/git-credential-manager"

# Tealdeer (tldr)
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME}/tealdeer"

# Local and user binary location (XDG-compliant)
export XDG_BIN_HOME="${XDG_BIN_HOME:-${XDG_DATA_HOME}/bin}"
export PATH="$XDG_BIN_HOME:$PATH"

# Ensure XDG_BIN_HOME exists for interactive shells
if [[ -n "$ZSH_NAME" ]] && [[ ! -d "$XDG_BIN_HOME" ]]; then
  mkdir -p "$XDG_BIN_HOME" 2>/dev/null || true
fi

# FZF default options
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --color=fg:-1,bg:-1,hl:#5f87af
  --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff
  --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
  --color=marker:#87ff00,spinner:#af5fff,header:#87afaf
'

# BAT (cat with syntax highlighting)
export BAT_THEME="TwoDark"
export BAT_STYLE="numbers,changes,header"

# ----------------------------------------------------------------------------
# History
# ----------------------------------------------------------------------------
export HISTSIZE=10000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME}/zsh/history"

# ----------------------------------------------------------------------------
# Compilation Flags
# ----------------------------------------------------------------------------
# Set architecture flags for compilation (mainly for macOS M1/M2)
if [[ "$OS_TYPE" == "macos" ]]; then
  export ARCHFLAGS="-arch $(uname -m)"
fi
