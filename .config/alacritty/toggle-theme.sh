#!/usr/bin/env bash
set -euo pipefail

# Use XDG Base Directory specification
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
THEME="$CFG/theme.toml"
LIGHT="$CFG/_light.toml"
DARK="$CFG/_dark.toml"

# Create theme.toml if it doesn't exist (default to dark)
if [[ ! -f "$THEME" ]]; then
  printf "[general]\n" > "$THEME"
  printf 'import = [ "%s" ]\n' "$DARK" >> "$THEME"
fi

# Read currently imported file path from theme.toml
current=$(grep -oE '"[^"]+"' "$THEME" | tr -d '"')

if [[ "$current" == "$LIGHT" ]]; then
  next="$DARK"
else
  next="$LIGHT"
fi

# Switch import (Alacritty will live-reload this)
printf "[general]\n" > "$THEME"  # Clear file
printf 'import = [ "%s" ]\n' "$next" >> "$THEME"
