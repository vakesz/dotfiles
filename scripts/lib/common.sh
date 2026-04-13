#!/usr/bin/env bash

info() {
    printf '\033[34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\033[32m[OK]\033[0m %s\n' "$1"
}

warn() {
    printf '\033[33m[WARN]\033[0m %s\n' "$1"
}

error() {
    printf '\033[31m[ERROR]\033[0m %s\n' "$1"
}

confirm() {
    local answer="n"
    read -r -n 1 -p $'\n'"$1"$' (y/N) ' answer || true
    echo ""
    [[ "$answer" =~ ^[Yy]$ ]]
}

detect_platform() {
    case "$OSTYPE" in
        darwin*)
            printf '%s\n' "macos"
            ;;
        linux*)
            printf '%s\n' "linux"
            ;;
        *)
            return 1
            ;;
    esac
}
