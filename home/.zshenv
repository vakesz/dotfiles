# .zshenv - Always sourced by zsh
# This file sets up XDG Base Directory specification variables

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Set ZDOTDIR to point to the XDG-compliant zsh config directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
