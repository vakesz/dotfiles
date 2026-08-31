#!/usr/bin/env bash
# Validate configuration with the applications that consume it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CHECKED_COUNT=0
SKIPPED_COUNT=0

checked() {
    printf '  ok   %s\n' "$1"
    ((CHECKED_COUNT += 1))
}

skipped() {
    printf '  skip %s (not installed)\n' "$1"
    ((SKIPPED_COUNT += 1))
}

if command -v starship >/dev/null 2>&1; then
    STARSHIP_CONFIG="$REPO_ROOT/config/starship.toml" starship print-config >/dev/null
    if [[ -n "$(STARSHIP_CONFIG="$REPO_ROOT/config/starship.toml" starship module c --path "$REPO_ROOT")" ]]; then
        printf 'error: Starship falsely detects the dotfiles repository as a C project\n' >&2
        exit 1
    fi
    checked "Starship"
else
    skipped "Starship"
fi

if command -v topgrade >/dev/null 2>&1; then
    topgrade \
        --config "$REPO_ROOT/config/topgrade.toml" \
        --dry-run \
        --only git_repos \
        --no-ask-retry >/dev/null
    checked "Topgrade"
else
    skipped "Topgrade"
fi

if command -v tldr >/dev/null 2>&1; then
    tldr \
        --config-path "$REPO_ROOT/config/tealdeer/config.toml" \
        --no-auto-update \
        --list >/dev/null
    checked "tealdeer"
else
    skipped "tealdeer"
fi

if command -v rg >/dev/null 2>&1; then
    RIPGREP_CONFIG_PATH="$REPO_ROOT/config/ripgrep/config" rg --files "$REPO_ROOT" >/dev/null
    checked "ripgrep"
else
    skipped "ripgrep"
fi

if command -v fd >/dev/null 2>&1; then
    fd --ignore-file "$REPO_ROOT/config/fd/ignore" --hidden . "$REPO_ROOT" >/dev/null
    checked "fd"
else
    skipped "fd"
fi

GHOSTTY_BIN="/Applications/Ghostty.app/Contents/MacOS/ghostty"
if [[ -x "$GHOSTTY_BIN" ]]; then
    "$GHOSTTY_BIN" +validate-config --config-file="$REPO_ROOT/config/ghostty/config"
    checked "Ghostty"
elif command -v ghostty >/dev/null 2>&1; then
    ghostty +validate-config --config-file="$REPO_ROOT/config/ghostty/config"
    checked "Ghostty"
else
    skipped "Ghostty"
fi

printf '\nvalidated %d installed application configs; skipped %d unavailable applications\n' \
    "$CHECKED_COUNT" "$SKIPPED_COUNT"
