# Environment, PATH, and Shell Settings

# XDG Base Directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Ensure PATH entries are unique
typeset -U path

# Platform Detection
case "$OSTYPE" in
  darwin*)
    export OS_TYPE="macos"
    ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      export OS_TYPE="wsl"
    else
      export OS_TYPE="linux"
    fi
    ;;
  *)
    export OS_TYPE="unknown"
    ;;
esac

# Helper Functions
have() {
  command -v "$1" >/dev/null 2>&1
}

_cache_init() {
  local bin_path cache_file cmd config_file
  bin_path=$(command -v "$1") || return 1
  cache_file="$2"
  cmd="$3"
  config_file="${4:-}"
  if [[ ! -f "$cache_file" || "$bin_path" -nt "$cache_file" || ( -n "$config_file" && "$config_file" -nt "$cache_file" ) ]]; then
    mkdir -p "${cache_file:h}"
    eval "$cmd" > "$cache_file" 2>/dev/null
  fi
  source "$cache_file"
}

_lazy_init() {
  local tool="$1" cmd="$2" config_file="${3:-}"
  have "$tool" || return 0
  _cache_init "$tool" "$XDG_CACHE_HOME/zsh/${tool}-init.zsh" "$cmd" "$config_file"
}

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export COLORTERM="truecolor"

# Editor
if have nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  export MANPAGER='nvim +Man!'
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

if [[ -t 0 ]]; then
  export GPG_TTY=$TTY
fi

# XDG paths for tools
export LESS='-R -i -M -W -x4 -F'
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
export MIX_XDG=1
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"
export NODE_REPL_HISTORY="${XDG_STATE_HOME}/node_repl_history"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}/bundle"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GCM_CREDENTIAL_CACHE_DIR="${XDG_CACHE_HOME}/git-credential-manager"
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME}/tealdeer"

export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
export PATH="$XDG_BIN_HOME:$PATH"

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

# PATH Configuration

add_keg_only() {
  local pkg="$1" bin="${2:-bin}"
  [[ -d "$HOMEBREW_PREFIX/opt/$pkg/$bin" ]] && export PATH="$HOMEBREW_PREFIX/opt/$pkg/$bin:$PATH"
}

if [[ "$OS_TYPE" == "macos" ]]; then
  local brew_path=""
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    brew_path="/opt/homebrew/bin/brew"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    brew_path="/usr/local/bin/brew"
  fi

  if [[ -n "$brew_path" ]]; then
    local brew_cache="$XDG_CACHE_HOME/zsh/brew_shellenv.zsh"
    local brew_hash_cache="$XDG_CACHE_HOME/zsh/brew_shellenv.hash"
    
    # Get current shellenv output and calculate its hash
    local current_shellenv
    current_shellenv=$("$brew_path" shellenv 2>/dev/null)
    local current_hash
    current_hash=$(echo "$current_shellenv" | md5)
    
    # Check if we need to update the cache
    local cached_hash=""
    [[ -f "$brew_hash_cache" ]] && cached_hash=$(<"$brew_hash_cache")
    
    if [[ "$current_hash" != "$cached_hash" || ! -f "$brew_cache" ]]; then
      mkdir -p "${brew_cache:h}"
      echo "$current_shellenv" > "$brew_cache"
      echo "$current_hash" > "$brew_hash_cache"
    fi
    
    source "$brew_cache"
  fi

  add_keg_only "curl"
  add_keg_only "ruby"
  add_keg_only "make" "libexec/gnubin"
  unfunction add_keg_only

elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  if [[ -d "/snap/bin" ]]; then
    export PATH="/snap/bin:$PATH"
  fi

  export NVM_DIR="${XDG_DATA_HOME}/nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _nvm_load() {
      unfunction nvm node npm npx _nvm_load 2>/dev/null
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

export UV_CACHE_DIR="${XDG_CACHE_HOME}/uv"
export UV_TOOL_DIR="${XDG_DATA_HOME}/uv/tools"
export UV_TOOL_BIN_DIR="${XDG_DATA_HOME}/uv/bin"
export UV_PYTHON_INSTALL_DIR="${XDG_DATA_HOME}/uv/python"
[[ -d "$UV_TOOL_BIN_DIR" ]] && export PATH="${UV_TOOL_BIN_DIR}:$PATH"

export BUN_INSTALL="${XDG_DATA_HOME}/bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# Shell Options
unsetopt FLOW_CONTROL
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt INTERACTIVE_COMMENTS

# History
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY

# History search with arrow keys
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Platform-specific
if [[ "$OS_TYPE" == "macos" ]]; then
  export ARCHFLAGS="-arch $CPUTYPE"
fi