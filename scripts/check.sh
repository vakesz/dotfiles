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

# Tracked plus untracked-but-not-ignored, minus paths an uncommitted rename or
# deletion left behind, so the lists never go stale and never break the run.
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
    command -v actionlint >/dev/null 2>&1 && actionlint

    git config --file config/git/config --list >/dev/null
    ruby -c Brewfile >/dev/null
    diff -u <(grep -vE '^(#|$)' config/fd/ignore) <(sed -n 's/^--glob=!\(.*\)$/\1/p' config/ripgrep/config)

    duplicates="$(sed -nE 's/^(brew|cask|vscode|uv) "([^"]+)".*/\2/p' Brewfile | sort | uniq -d)"
    if [[ -n "$duplicates" ]]; then
        printf 'duplicate Brewfile entries:\n%s\n' "$duplicates"
        exit 1
    fi

    # The empty tree makes every committed line an added line; HEAD then covers
    # uncommitted work, which a clean CI checkout does not have.
    git diff --check "$(git hash-object -t tree /dev/null)" HEAD
    git diff --check HEAD

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
