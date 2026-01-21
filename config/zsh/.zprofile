# ============================================================================
# .zprofile - Zsh Profile (Login Shells)
# ============================================================================
# Loaded for login shells before .zshrc
#
# This file sets up the XDG Base Directory specification.
# Most configuration is in .zshrc and config.d/ modules.

# ----------------------------------------------------------------------------
# Create XDG Directories
# ----------------------------------------------------------------------------

# Ensure XDG directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" 2>/dev/null

# Create subdirectories for specific tools
mkdir -p "${XDG_STATE_HOME}/zsh" 2>/dev/null       # zsh history
mkdir -p "${XDG_CACHE_HOME}/zsh" 2>/dev/null       # zsh cache
mkdir -p "${XDG_DATA_HOME}/zinit" 2>/dev/null      # zinit plugins

# ----------------------------------------------------------------------------
# macOS-Specific Login Shell Configuration
# ----------------------------------------------------------------------------

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Set PATH for GUI applications on macOS
  # This ensures apps launched from Finder have correct PATH
  if [[ -f /usr/libexec/path_helper ]]; then
    eval "$(/usr/libexec/path_helper -s)"
  fi

  # Disable macOS shell session restoration
  # This prevents .zsh_sessions directory from cluttering $ZDOTDIR
  # Session files are state data and don't belong in config directory
  export SHELL_SESSIONS_DISABLE=1
fi
