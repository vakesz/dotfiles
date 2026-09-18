#!/usr/bin/env bash
# Validate this repo's configuration with the applications that consume it.

set -euo pipefail

# shellcheck source=scripts/lib/paths.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/paths.sh"
# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"

validate() {
    local label="$1" bin="$2"
    shift 2

    if command -v "$bin" >/dev/null 2>&1; then
        "$@" >/dev/null
        pass "$label"
    else
        skip "$label (not installed)"
    fi
}

check_starship() {
    local config="$DOTFILES_ROOT/config/starship.toml"

    if ! command -v starship >/dev/null 2>&1; then
        skip "Starship (not installed)"
        return 0
    fi

    STARSHIP_CONFIG="$config" starship print-config >/dev/null

    # A match here means the repo's own dot-c-free tree reads as a C project,
    # which would put a C version in the prompt of every directory like it.
    if [[ -n "$(STARSHIP_CONFIG="$config" starship module c --path "$DOTFILES_ROOT")" ]]; then
        printf 'error: Starship falsely detects the dotfiles repository as a C project\n' >&2
        exit 1
    fi

    pass "Starship"
}

check_ghostty() {
    local bundle="/Applications/Ghostty.app/Contents/MacOS/ghostty"
    local config="--config-file=$DOTFILES_ROOT/config/ghostty/config"

    # The cask installs no ghostty on PATH, so try the app bundle first.
    if [[ -x "$bundle" ]]; then
        "$bundle" +validate-config "$config"
    elif command -v ghostty >/dev/null 2>&1; then
        ghostty +validate-config "$config"
    else
        skip "Ghostty (not installed)"
        return 0
    fi

    pass "Ghostty"
}

main() {
    check_starship

    validate Topgrade topgrade \
        topgrade --config "$DOTFILES_ROOT/config/topgrade.toml" --dry-run --only git_repos --no-ask-retry
    validate tealdeer tldr \
        tldr --config-path "$DOTFILES_ROOT/config/tealdeer/config.toml" --no-auto-update --list
    validate ripgrep rg \
        env RIPGREP_CONFIG_PATH="$DOTFILES_ROOT/config/ripgrep/config" rg --files "$DOTFILES_ROOT"
    validate fd fd \
        fd --ignore-file "$DOTFILES_ROOT/config/fd/ignore" --hidden . "$DOTFILES_ROOT"

    check_ghostty

    printf '\nvalidated %d installed application configs; skipped %d unavailable applications\n' \
        "$PASS_COUNT" "$SKIP_COUNT"
}

main "$@"
