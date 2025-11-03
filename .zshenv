# .zshenv - Always sourced by zsh
# This file sets up the ZDOTDIR to follow XDG Base Directory specification

# Set ZDOTDIR to point to the XDG-compliant zsh config directory
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
