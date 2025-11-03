# ============================================================================
# .zprofile - Zsh Profile (Login Shells)
# ============================================================================
# Loaded for login shells before .zshrc
#
# This file sets up the XDG Base Directory specification.
# Most configuration is in .zshrc and config.d/ modules.

# ----------------------------------------------------------------------------
# XDG Base Directory Specification
# ----------------------------------------------------------------------------

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ----------------------------------------------------------------------------
# Create XDG Directories
# ----------------------------------------------------------------------------

# Ensure XDG directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# Create subdirectories for specific tools
mkdir -p "${XDG_STATE_HOME}/zsh"       # zsh history
mkdir -p "${XDG_CACHE_HOME}/zsh"       # zsh cache
mkdir -p "${XDG_DATA_HOME}/zinit"      # zinit plugins

# ----------------------------------------------------------------------------
# macOS-Specific Login Shell Configuration
# ----------------------------------------------------------------------------

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Set PATH for GUI applications on macOS
  # This ensures apps launched from Finder have correct PATH
  if [[ -f /usr/libexec/path_helper ]]; then
    eval "$(/usr/libexec/path_helper -s)"
  fi
fi
