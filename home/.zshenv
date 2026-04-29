export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Tool config/cache redirects (apply to non-interactive shells too).
export LESS='-R -i -M -W -x4 -F'
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/gem"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GCM_CREDENTIAL_CACHE_DIR="$XDG_CACHE_HOME/git-credential-manager"
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

# Toolchain locations (PATH appends still happen in rc.d/20-path.zsh).
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_TOOL_DIR="$XDG_DATA_HOME/uv/tools"
export UV_TOOL_BIN_DIR="$XDG_DATA_HOME/uv/bin"
export UV_PYTHON_INSTALL_DIR="$XDG_DATA_HOME/uv/python"
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

# Prevent .zsh_sessions from cluttering $ZDOTDIR on macOS.
[[ "$OSTYPE" == darwin* ]] && export SHELL_SESSIONS_DISABLE=1
