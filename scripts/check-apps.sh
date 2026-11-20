#!/usr/bin/env bash
# Validate this repo's configuration with the applications that consume it.
# A failed validation is reported and the rest still run; the exit status is
# non-zero if any failed.

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"

validate() {
    local label="$1" bin="$2"
    shift 2

    if ! has_command "$bin"; then
        skip "$label (not installed)"
    elif "$@" >/dev/null; then
        pass "$label"
    else
        fail "$label"
    fi
}

check_starship() {
    local config="$DOTFILES_ROOT/config/starship.toml"

    if ! has_command starship; then
        skip "Starship (not installed)"
        return 0
    fi

    if ! STARSHIP_CONFIG="$config" starship print-config >/dev/null; then
        fail "Starship"
        return 0
    fi

    # This repo has no C files. If Starship still detects C here, the prompt
    # would show a C module in every similar directory.
    if [[ -n "$(STARSHIP_CONFIG="$config" starship module c --path "$DOTFILES_ROOT")" ]]; then
        fail "Starship falsely detects the dotfiles repository as a C project"
        return 0
    fi

    pass "Starship"
}

check_ghostty() {
    local ghostty="/Applications/Ghostty.app/Contents/MacOS/ghostty"
    local config="--config-file=$DOTFILES_ROOT/config/ghostty/config"

    # The cask doesn't put ghostty on PATH, so prefer the app bundle.
    if [[ ! -x "$ghostty" ]]; then
        if ! has_command ghostty; then
            skip "Ghostty (not installed)"
            return 0
        fi
        ghostty="ghostty"
    fi

    if "$ghostty" +validate-config "$config"; then
        pass "Ghostty"
    else
        fail "Ghostty"
    fi
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

    printf '\nvalidated %d installed application configs; %d failed; skipped %d unavailable applications\n' \
        "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    ((FAIL_COUNT == 0))
}

main "$@"
