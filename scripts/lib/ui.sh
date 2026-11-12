#!/usr/bin/env bash
# Status messages, prompts and check results. The only file in scripts/ that
# prints ANSI colors.

[[ -n "${__DOTFILES_UI_LOADED:-}" ]] && return 0
__DOTFILES_UI_LOADED=1

# Print "label message" to file descriptor fd, coloring the label with SGR
# code sgr only when fd is a terminal and NO_COLOR is unset (no-color.org).
# Callers must not wrap this in $(...): stdout is a pipe there.
_ui_print() {
    local fd="$1" sgr="$2" label="$3" message="$4"

    if [[ -z "${NO_COLOR:-}" && -t "$fd" ]]; then
        printf '\033[%sm%s\033[0m %s\n' "$sgr" "$label" "$message" >&"$fd"
    else
        printf '%s %s\n' "$label" "$message" >&"$fd"
    fi
}

# Print a blue informational message to stdout.
info() {
    _ui_print 1 34 '[INFO]' "$1"
}

# Print a green success message to stdout.
success() {
    _ui_print 1 32 '[OK]' "$1"
}

# Print a yellow warning to stderr.
warn() {
    _ui_print 2 33 '[WARN]' "$1"
}

# Print a red error to stderr.
error() {
    _ui_print 2 31 '[ERROR]' "$1"
}

# Print a red error to stderr and exit 1.
die() {
    error "$1"
    exit 1
}

# True when both stdin and stdout are terminals.
is_interactive() {
    [[ -t 0 && -t 1 ]]
}

# Print the prompt timeout in seconds: DOTFILES_CONFIRM_TIMEOUT, else 30.
# 0 would make `read -t` give up at once, so it counts as unset.
prompt_timeout() {
    local timeout="${DOTFILES_CONFIRM_TIMEOUT:-30}"
    [[ "$timeout" =~ ^[1-9][0-9]*$ ]] || timeout=30
    printf '%s\n' "$timeout"
}

# Ask a y/N question; defaults to No on timeout or non-interactive shells.
confirm() {
    local answer="n" timeout=""

    is_interactive || return 1
    timeout="$(prompt_timeout)"

    printf '\n%s (y/N) ' "$1"

    # Read a whole line so Enter is consumed. `read -n 1` would leave the newline
    # behind, and the next prompt would read it as No.
    if ! IFS= read -r -t "$timeout" answer; then
        printf '\n'
        warn "No confirmation input received; defaulting to No"
        return 1
    fi

    # Trim surrounding whitespace so "y " still counts as yes.
    answer="${answer#"${answer%%[![:space:]]*}"}"
    answer="${answer%"${answer##*[![:space:]]}"}"

    case "$answer" in
        y | Y | yes | YES | Yes) return 0 ;;
        *) return 1 ;;
    esac
}

# Offer to run "$@" after confirmation. Always returns 0.
offer() {
    local prompt="$1"
    shift

    confirm "$prompt" || return 0

    # `"$@" || warn ...` would make bash ignore errexit for the whole action, so
    # a failed step would still print [OK]. Run it as a plain statement in a
    # subshell instead, so variables it sets do not persist.
    local status=0 had_errexit=0
    [[ $- == *e* ]] && had_errexit=1
    set +e
    (
        set -e
        "$@"
    )
    status=$?
    ((had_errexit)) && set -e
    ((status == 0)) || warn "$1 did not complete"
    return 0
}

# Run action_fn after confirmation unless check_fn already passes.
offer_if_missing() {
    local prompt="$1" check_fn="$2" action_fn="$3" already_message="$4"

    if "$check_fn"; then
        info "$already_message"
        return 0
    fi

    offer "$prompt" "$action_fn"
}

# Skip the caller's step with info when $1 is missing from PATH.
require_command() {
    command -v "$1" >/dev/null 2>&1 && return 0
    info "$1 not installed; skipping ${2:-$1}"
    return 1
}

PASS_COUNT="${PASS_COUNT:-0}"
FAIL_COUNT="${FAIL_COUNT:-0}"
WARN_COUNT="${WARN_COUNT:-0}"
SKIP_COUNT="${SKIP_COUNT:-0}"

section() {
    printf '\n'
    if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
        printf '\033[1m%s\033[0m\n' "$1"
    else
        printf '%s\n' "$1"
    fi
}

# `((X += 1))`, not `((X++))`: the latter returns 1 when X is 0, which aborts
# `set -e` callers.
pass() {
    _ui_print 1 32 '  ok  ' "$1"
    ((PASS_COUNT += 1))
}

fail() {
    _ui_print 1 31 ' fail ' "$1"
    ((FAIL_COUNT += 1))
}

soft_warn() {
    _ui_print 1 33 ' warn ' "$1"
    ((WARN_COUNT += 1))
}

skip() {
    _ui_print 1 34 ' skip ' "$1"
    ((SKIP_COUNT += 1))
}
