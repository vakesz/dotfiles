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
export LESSHISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/less/history"

# Ripgrep config
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/config"

# Wget config (use XDG location for wgetrc)
export WGETRC="${XDG_CONFIG_HOME:-$HOME/.config}/wget/wgetrc"

# Python: Use XDG for pycache (Python 3.8+)
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-$HOME/.cache}/python"

# Elixir Mix: Enable XDG support
export MIX_XDG=1

# ----------------------------------------------------------------------------
# Application-Specific XDG Compliance
# ----------------------------------------------------------------------------
# These prevent individual apps from polluting HOME

# Node.js version managers
export N_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/node"
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"

# Ruby bundler
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/bundle"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/bundle"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME:-$HOME/.local/share}/bundle"

# Jupyter
export JUPYTER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/jupyter"

# PostgreSQL
export PSQLRC="${XDG_CONFIG_HOME:-$HOME/.config}/pg/psqlrc"
export PSQL_HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/psql_history"
export PGPASSFILE="${XDG_CONFIG_HOME:-$HOME/.config}/pg/pgpass"
export PGSERVICEFILE="${XDG_CONFIG_HOME:-$HOME/.config}/pg/pg_service.conf"

# MySQL/MariaDB
export MYSQL_HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/mysql_history"

# SQLite
export SQLITE_HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/sqlite_history"

# GnuPG
export GNUPGHOME="${XDG_DATA_HOME:-$HOME/.local/share}/gnupg"

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
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
export HISTDUP=erase

# ----------------------------------------------------------------------------
# Compilation Flags
# ----------------------------------------------------------------------------
# Set architecture flags for compilation (mainly for macOS M1/M2)
if [[ "$OS_TYPE" == "macos" ]]; then
  export ARCHFLAGS="-arch $(uname -m)"
fi
