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

# Initialize Oh My Posh with zen theme (cached for speed)
if have oh-my-posh; then
  omp_config="${XDG_CONFIG_HOME:-$HOME/.config}/oh-my-posh/zen.toml"
  omp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/oh-my-posh-init.zsh"
  omp_bin=""
  omp_bin=$(command -v oh-my-posh)

  if [[ ! -f "$omp_cache" ]] || \
     [[ "$omp_config" -nt "$omp_cache" ]] || \
     [[ "$omp_bin" -nt "$omp_cache" ]]; then
    mkdir -p "${omp_cache:h}"
    oh-my-posh init zsh --config "$omp_config" > "$omp_cache" 2>/dev/null
  fi
  source "$omp_cache"
else
  PROMPT='%F{#9ccfd8}%~%f %F{#908caa}❯%f '
fi

# ----------------------------------------------------------------------------
# Local Customizations
# ----------------------------------------------------------------------------

# Source local customizations (not tracked in git)
source_if_exists "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.local"
