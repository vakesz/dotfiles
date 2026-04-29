#!/usr/bin/env bash
#
# Optional Linux / WSL setup for this dotfiles repo.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DISTRO_ID=""
DISTRO_LIKE=""
LINUX_VARIANT="linux"

source "$REPO_ROOT/scripts/lib/common.sh"

require_linux() {
    [[ "$OSTYPE" == linux* ]] || {
        error "This script is for Linux or WSL only"
        exit 1
    }
}

persist_locale_with_systemd() {
    if command -v localectl >/dev/null 2>&1; then
        sudo localectl set-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    else
        warn "localectl not found; writing /etc/locale.conf directly"
        {
            echo "LANG=en_US.UTF-8"
            echo "LC_ALL=en_US.UTF-8"
        } | sudo tee /etc/locale.conf >/dev/null
    fi
}

load_linux_release_info() {
    DISTRO_ID=""
    DISTRO_LIKE=""
    LINUX_VARIANT="linux"

    if grep -qi microsoft /proc/version 2>/dev/null; then
        LINUX_VARIANT="wsl"
    fi

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-}"
        DISTRO_LIKE="${ID_LIKE:-}"
    fi
}

distro_family() {
    case "$DISTRO_ID" in
        debian|ubuntu) printf 'debian\n'; return 0 ;;
        fedora) printf 'redhat\n'; return 0 ;;
        arch) printf 'arch\n'; return 0 ;;
    esac
    case "$DISTRO_LIKE" in
        *debian*) printf 'debian\n' ;;
        *rhel*|*fedora*) printf 'redhat\n' ;;
        *arch*) printf 'arch\n' ;;
        *) return 1 ;;
    esac
}

install_locale_for_family() {
    case "$1" in
        debian)
            command -v apt-get >/dev/null 2>&1 || { warn "apt-get not found; skipping locale install"; return 0; }
            sudo apt-get update -qq
            sudo apt-get install -y locales
            sudo locale-gen en_US.UTF-8
            success "Locale en_US.UTF-8 generated"
            ;;
        redhat)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y glibc-langpack-en
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y glibc-langpack-en
            else
                warn "dnf/yum not found; skipping locale install"
                return 0
            fi
            success "Locale en_US.UTF-8 installed"
            ;;
        arch)
            [[ -f /etc/locale.gen ]] || { warn "/etc/locale.gen not found; skipping locale generation"; return 0; }
            sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
            sudo locale-gen
            success "Locale en_US.UTF-8 generated"
            ;;
    esac
}

persist_locale_for_family() {
    if [[ "$1" == "debian" ]] && command -v update-locale >/dev/null 2>&1; then
        sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    else
        persist_locale_with_systemd
    fi
}

ensure_locale() {
    load_linux_release_info

    info "Detected platform: $LINUX_VARIANT"

    local family=""
    family="$(distro_family)" || {
        warn "Unsupported Linux distro for locale setup; skipping"
        return 0
    }

    if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
        info "Locale en_US.UTF-8 already available"
    else
        info "Installing en_US.UTF-8 locale..."
        install_locale_for_family "$family"
    fi

    persist_locale_for_family "$family"
}

ensure_pnpm() {
    if ! command -v corepack >/dev/null 2>&1; then
        warn "corepack not found; install Node (e.g. via NVM) first, then re-run"
        return 0
    fi

    if command -v pnpm >/dev/null 2>&1; then
        info "pnpm already available"
        return 0
    fi

    info "Enabling pnpm via corepack..."
    corepack enable pnpm
    success "pnpm enabled"
}

ensure_zsh_shell() {
    local zsh_path=""

    zsh_path="$(command -v zsh)" || {
        warn "zsh not installed"
        return 0
    }

    if [[ "$(basename "$SHELL")" == "zsh" ]]; then
        info "Shell is already zsh"
        return 0
    fi

    info "Changing default shell to zsh..."
    grep -Fxq "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null

    if chsh -s "$zsh_path"; then
        success "Default shell changed to zsh (log out and back in to apply)"
    else
        error "Failed to change shell"
        return 1
    fi
}

main() {
    require_linux

    info "Linux / WSL setup"

    confirm "Configure en_US.UTF-8 locale?" && ensure_locale
    confirm "Set zsh as the default shell?" && ensure_zsh_shell
    confirm "Enable pnpm via corepack?" && ensure_pnpm

    success "Done!"
}

main "$@"
