#!/usr/bin/env bash
# Validate the repository itself: bash lint, bash formatting, zsh syntax, structured config.

set -euo pipefail

# shellcheck source=scripts/lib/paths.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/paths.sh"
# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES_ROOT/scripts/lib/ui.sh"

FILES=()

# Abort unless the named command exists on PATH.
require() {
    command -v "$1" >/dev/null 2>&1 || die "$1 not installed${2:+: $2}"
}

# Tracked and untracked (but not ignored) files that still exist, so an
# uncommitted rename or deletion never breaks a check.
collect() {
    local file allow_empty=0

    if [[ "${1:-}" == "--allow-empty" ]]; then
        allow_empty=1
        shift
    fi

    FILES=()
    while IFS= read -r file; do
        if [[ -e "$file" ]]; then
            FILES+=("$file")
        fi
    done < <(git ls-files -co --exclude-standard -- "$@" | sort -u)

    if ((allow_empty == 0)); then
        ((${#FILES[@]} > 0)) || die "no files matched: $*"
    fi
}

# Shellcheck every bash script in the repo.
check_shell() {
    require shellcheck "brew install shellcheck"
    collect '*.sh'

    shellcheck --shell=bash --external-sources "${FILES[@]}"
    printf 'shellcheck: clean\n'
}

# Verify shfmt formatting for every bash script. The style comes from
# .editorconfig; shfmt ignores that file as soon as any formatting flag is set.
check_fmt() {
    require shfmt "brew install shfmt"
    collect '*.sh'

    shfmt -d "${FILES[@]}"
    printf 'shfmt: clean\n'
}

# Parse every Zsh configuration file with zsh -n.
check_zsh() {
    local file

    require zsh
    collect '*.zsh' '*.zshenv' '*.zshrc' '*.zprofile'

    for file in "${FILES[@]}"; do
        zsh -n "$file" || exit 1
    done
    printf 'zsh syntax: clean\n'
}

# Report whitespace errors in untracked files.
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

# Validate JSON files with jq.
check_json() {
    collect --allow-empty '*.json'
    ((${#FILES[@]} == 0)) && return 0

    jq empty "${FILES[@]}"
}

# Newest python3 with stdlib tomllib (3.11+). Plain python3 may be Apple's
# 3.9, while Homebrew only links versioned names like python3.14.
toml_python() {
    local candidate
    for candidate in python3 python3.14 python3.13 python3.12 python3.11; do
        command -v "$candidate" >/dev/null 2>&1 || continue
        "$candidate" -c 'import tomllib' 2>/dev/null || continue
        printf '%s\n' "$candidate"
        return 0
    done
    return 1
}

# Validate TOML files with Python's stdlib parser.
check_toml() {
    local py=""

    collect --allow-empty '*.toml'
    ((${#FILES[@]} == 0)) && return 0

    py="$(toml_python)" || die "no python3 with tomllib found (need 3.11+)"
    "$py" -c 'import sys, tomllib; [tomllib.load(open(path, "rb")) for path in sys.argv[1:]]' "${FILES[@]}"
}

# Lint GitHub workflows with actionlint when available.
check_actionlint() {
    # Optional locally, but required in CI so the workflow lint can't be skipped.
    if [[ -n "${CI:-}" ]]; then
        require actionlint
    fi
    if command -v actionlint >/dev/null 2>&1; then
        actionlint
    fi
}

# Validate gitconfig syntax, Brewfile syntax, and fd/ripgrep sync.
check_app_syntax() {
    git config --file config/git/config --list >/dev/null
    ruby -c Brewfile >/dev/null
    diff -u <(grep -vE '^(#|$)' config/fd/ignore) <(sed -n 's/^--glob=!\(.*\)$/\1/p' config/ripgrep/config)
}

# Fail on duplicate Brewfile entries (brews, casks, mas apps, vscode/uv).
check_brewfile_duplicates() {
    local duplicates=""

    duplicates="$(sed -nE 's/^(brew|cask|mas|vscode|uv) "([^"]+)".*/\2/p' Brewfile | sort | uniq -d)"
    if [[ -n "$duplicates" ]]; then
        printf 'duplicate Brewfile entries:\n%s\n' "$duplicates"
        exit 1
    fi
}

# Print NAME=value for each variable named in $3.. as a login-less zsh at path
# $1 sees it with HOME=$2 and nothing else in the environment.
zsh_env_values() {
    local zsh_path="$1" home="$2"
    shift 2
    # shellcheck disable=SC2016 # expanded by zsh, not here
    env -i HOME="$home" PATH=/usr/bin:/bin "$zsh_path" -c 'for v; do print -r -- "$v=${(P)v}"; done' zsh "$@"
}

# Print NAME=value for each variable named in $2.. after paths.sh applies its
# defaults with HOME=$1 and nothing else in the environment.
bash_env_values() {
    local home="$1"
    shift
    # shellcheck disable=SC2016 # expanded by the child bash, not here
    env -i HOME="$home" PATH=/usr/bin:/bin "$BASH" -c \
        'source "$1"; shift; set_xdg_environment_defaults; for v; do printf "%s=%s\n" "$v" "${!v}"; done' \
        bash "$DOTFILES_ROOT/scripts/lib/paths.sh" "$@"
}

# Fail when scripts/lib/paths.sh and the zsh environment disagree on a
# variable paths.sh exports. bootstrap and doctor run in bash, so paths.sh
# repeats those defaults by hand. The zsh side starts a real shell in a temp
# HOME laid out like a stowed machine, so it doesn't matter which startup
# file holds the exports.
check_xdg_drift() {
    local tmp="" names=() name zsh_path="" zsh_values="" bash_values="" status=0

    while IFS= read -r name; do
        names+=("$name")
    done < <(sed -n 's/^ *export \([A-Z_][A-Z0-9_]*\)=.*/\1/p' scripts/lib/paths.sh)
    ((${#names[@]} > 0)) || die "no exports found in scripts/lib/paths.sh"

    # The clean PATH below may not contain zsh (Homebrew, Linuxbrew, nix), so
    # call it by absolute path.
    zsh_path="$(command -v zsh)"

    tmp="$(mktemp -d)"
    mkdir -p "$tmp/.config"
    ln -s "$DOTFILES_ROOT/home/.zshenv" "$tmp/.zshenv"
    ln -s "$DOTFILES_ROOT/config/zsh" "$tmp/.config/zsh"

    zsh_values="$(zsh_env_values "$zsh_path" "$tmp" "${names[@]}")" || status=$?
    bash_values="$(bash_env_values "$tmp" "${names[@]}")" || status=$?
    rm -rf -- "$tmp"

    # A shell that failed to start is a broken check, not drift.
    if ((status != 0)) || [[ -z "$zsh_values" || -z "$bash_values" ]]; then
        die "could not read the environment from $zsh_path or paths.sh (exit $status)"
    fi

    diff -u --label config/zsh/.zshenv --label scripts/lib/paths.sh \
        <(printf '%s\n' "$zsh_values") <(printf '%s\n' "$bash_values") ||
        die "scripts/lib/paths.sh defaults drifted from the zsh environment"
}

# Check committed lines, local edits, and untracked files for whitespace.
check_whitespace() {
    git diff --check "$(git hash-object -t tree /dev/null)" HEAD
    git diff --check HEAD
    check_untracked_whitespace
}

check_config() {
    require jq
    require ruby
    require zsh
    toml_python >/dev/null || die "no python3 with tomllib found (need 3.11+)"

    check_json
    check_toml
    check_actionlint
    check_app_syntax
    check_brewfile_duplicates
    check_xdg_drift
    check_whitespace

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
        *) die "usage: ${0##*/} [shell|fmt|zsh|config|all]" ;;
    esac
}

main "$@"
