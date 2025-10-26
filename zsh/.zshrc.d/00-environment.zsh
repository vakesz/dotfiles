# Description: XDG Base Directory and locale configuration
# Load order: First (environment variables should be set early)

# ============================================================================
# XDG Base Directories
# ============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ============================================================================
# Locale Configuration
# ============================================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# ============================================================================
# Less/Pager Configuration
# ============================================================================
export LESS='-R -F -X -i'  # Raw color codes, quit if one screen, no init, case-insensitive search
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# ============================================================================
# Python Configuration
# ============================================================================
export PYTHONSTARTUP="${XDG_CONFIG_HOME:-$HOME/.config}/python/pythonrc"
export PYTHON_HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/python/history"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-$HOME/.cache}/python"
export PYTHONUSERBASE="${XDG_DATA_HOME:-$HOME/.local/share}/python"

# pip - use XDG directories
export PIP_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pip/pip.conf"
export PIP_LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pip/log"

# ============================================================================
# Ripgrep Configuration
# ============================================================================
if have rg; then
    export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
fi
