#!/usr/bin/env bash
# Validate the repository itself: bash lint, bash formatting, zsh syntax, structured config.

set -euo pipefail

# shellcheck source=scripts/lib/paths.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/paths.sh"

FILES=()

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

require() {
    command -v "$1" >/dev/null 2>&1 || die "$1 not installed${2:+: $2}"
}

# Tracked and untracked (but not ignored) files that still exist, so an
# uncommitted rename or deletion never breaks a check.
collect() {
    local file

    FILES=()
    while IFS= read -r file; do
        if [[ -e "$file" ]]; then
            FILES+=("$file")
        fi
    done < <(git ls-files -co --exclude-standard -- "$@" | sort -u)

    ((${#FILES[@]} > 0)) || die "no files matched: $*"
}

check_shell() {
    require shellcheck "brew install shellcheck"
    collect '*.sh'

    shellcheck --shell=bash --external-sources "${FILES[@]}"
    printf 'shellcheck: clean\n'
}

check_fmt() {
    require shfmt "brew install shfmt"
    collect '*.sh'

    shfmt -i 4 -ci -d "${FILES[@]}"
    printf 'shfmt: clean\n'
}

check_zsh() {
    local file

    require zsh
    collect '*.zsh' '*.zshenv' '*.zshrc' '*.zprofile'

    for file in "${FILES[@]}"; do
        zsh -n "$file" || exit 1
    done
    printf 'zsh syntax: clean\n'
}

check_untracked_whitespace() {
    local file output

    while IFS= read -r file; do
        output="$(git diff --no-index --check /dev/null "$file" 2>&1 || true)"
        if [[ -n "$output" ]]; then
            printf '%s\n' "$output" >&2
            return 1
        fi
    done < <(git ls-files --others --exclude-standard)
}

check_config() {
    local duplicates=""

    require jq
    require python3
    require ruby

    collect '*.json'
    jq empty "${FILES[@]}"

    collect '*.toml'
    python3 -c 'import sys, tomllib; [tomllib.load(open(path, "rb")) for path in sys.argv[1:]]' "${FILES[@]}"

    collect '*.yml' '*.yaml'
    ruby -e 'require "yaml"; ARGV.each { |path| YAML.safe_load_file(path, aliases: true) }' "${FILES[@]}"
    # Optional locally, but required in CI so the workflow lint can't be skipped.
    if [[ -n "${CI:-}" ]]; then
        require actionlint
    fi
    if command -v actionlint >/dev/null 2>&1; then
        actionlint
    fi

    git config --file config/git/config --list >/dev/null
    ruby -c Brewfile >/dev/null
    diff -u <(grep -vE '^(#|$)' config/fd/ignore) <(sed -n 's/^--glob=!\(.*\)$/\1/p' config/ripgrep/config)

    duplicates="$(sed -nE 's/^(brew|cask|vscode|uv) "([^"]+)".*/\2/p' Brewfile | sort | uniq -d)"
    if [[ -n "$duplicates" ]]; then
        printf 'duplicate Brewfile entries:\n%s\n' "$duplicates"
        exit 1
    fi

    # Check every committed line, then local edits, then untracked files.
    git diff --check "$(git hash-object -t tree /dev/null)" HEAD
    git diff --check HEAD
    check_untracked_whitespace

    printf 'config syntax and whitespace: clean\n'
}

main() {
    cd "$DOTFILES_ROOT"

    case "${1:-all}" in
        shell) check_shell ;;
        fmt) check_fmt ;;
        zsh) check_zsh ;;
        config) check_config ;;
        all)
            check_shell
            check_fmt
            check_zsh
            check_config
            ;;
        *) die "usage: $(basename "$0") [shell|fmt|zsh|config|all]" ;;
    esac
}

main "$@"
