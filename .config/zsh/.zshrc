# ============================================================================
# .zshrc - Zsh Configuration for Interactive Shells
# ============================================================================
# This file loads modular configuration from config.d/
#
# Load order:
#   1. platform.zsh  - OS detection and helper functions
#   2. path.zsh      - PATH configuration
#   3. env.zsh       - Environment variables
#   4. plugins.zsh   - Zinit plugins
#   5. completion.zsh - Completion system
#   6. aliases.zsh   - Aliases and functions
#   7. prompt        - Oh My Posh prompt

# Configuration directory
CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/config.d"

# ----------------------------------------------------------------------------
# Source Configuration Modules
# ----------------------------------------------------------------------------

# Helper function to source files
source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

# Load modules in order
source_if_exists "$CONFIG_DIR/platform.zsh"
source_if_exists "$CONFIG_DIR/path.zsh"
source_if_exists "$CONFIG_DIR/env.zsh"
source_if_exists "$CONFIG_DIR/plugins.zsh"
source_if_exists "$CONFIG_DIR/completion.zsh"
source_if_exists "$CONFIG_DIR/aliases.zsh"

# ----------------------------------------------------------------------------
# Oh My Posh Prompt
# ----------------------------------------------------------------------------

# Initialize Oh My Posh with zen theme
if have oh-my-posh; then
  eval "$(oh-my-posh init zsh --config ${XDG_CONFIG_HOME:-$HOME/.config}/oh-my-posh/zen.toml)"
else
  # Fallback to simple prompt if oh-my-posh not installed
  PROMPT='%F{blue}%~%f %F{magenta}❯%f '
fi

# ----------------------------------------------------------------------------
# Local Customizations
# ----------------------------------------------------------------------------

# Source local customizations (not tracked in git)
source_if_exists "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.local"

export NVM_DIR="$HOME/.local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
