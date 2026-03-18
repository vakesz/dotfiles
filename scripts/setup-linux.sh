#!/usr/bin/env bash
#
# Optional Linux / WSL machine setup for this dotfiles repo.
#

set -euo pipefail

# Logging
info()    { printf '\033[34m[INFO]\033[0m %s\n' "$1"; }
success() { printf '\033[32m[OK]\033[0m %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m %s\n' "$1"; }
error()   { printf '\033[31m[ERROR]\033[0m %s\n' "$1"; }

# Interactive prompt helper
ask() {
    local answer="n"
    read -r -n 1 -p $'\n'"$1"$' (y/N) ' answer || true
    echo ""
    [[ "$answer" =~ ^[Yy]$ ]]
}

require_linux() {
    [[ "$OSTYPE" == linux* ]] || { error "This script is for Linux or WSL only"; exit 1; }
}

set_locale_systemd() {
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

load_distro_info() {
    DISTRO_ID=""
    DISTRO_LIKE=""
    PLATFORM_NAME="linux"

    if grep -qi microsoft /proc/version 2>/dev/null; then
        PLATFORM_NAME="wsl"
    fi

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-}"
        DISTRO_LIKE="${ID_LIKE:-}"
    fi
}

setup_locale() {
    load_distro_info

    info "Detected platform: $PLATFORM_NAME"

    if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
        info "Locale en_US.UTF-8 already available"
    else
        info "Installing en_US.UTF-8 locale..."
        if [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update -qq
                sudo apt-get install -y locales
                sudo locale-gen en_US.UTF-8
                success "Locale en_US.UTF-8 generated"
            else
                warn "apt-get not found; skipping locale install"
            fi
        elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" == *"rhel"* || "$DISTRO_LIKE" == *"fedora"* ]]; then
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y glibc-langpack-en
                success "Locale en_US.UTF-8 installed"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y glibc-langpack-en
                success "Locale en_US.UTF-8 installed"
            else
                warn "dnf/yum not found; skipping locale install"
            fi
        elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
            if [[ -f /etc/locale.gen ]]; then
                sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
                sudo locale-gen
                success "Locale en_US.UTF-8 generated"
            else
                warn "/etc/locale.gen not found; skipping locale generation"
            fi
        else
            warn "Unsupported Linux distro for locale setup; skipping"
            return 0
        fi
    fi

    if [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* ]]; then
        if command -v update-locale >/dev/null 2>&1; then
            sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
        else
            set_locale_systemd
        fi
    elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" == *"rhel"* || "$DISTRO_LIKE" == *"fedora"* || "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        set_locale_systemd
    fi
}

setup_default_shell() {
    command -v zsh >/dev/null 2>&1 || { warn "zsh not installed"; return 0; }

    if [[ "$(basename "$SHELL")" == "zsh" ]]; then
        info "Shell is already zsh"
        return 0
    fi

    info "Changing default shell to zsh..."
    grep -Fxq "$(command -v zsh)" /etc/shells 2>/dev/null || command -v zsh | sudo tee -a /etc/shells >/dev/null

    if chsh -s "$(command -v zsh)"; then
        success "Default shell changed to zsh (log out and back in to apply)"
    else
        error "Failed to change shell"
        return 1
    fi
}

main() {
    require_linux

    info "Optional Linux / WSL setup"

    ask "Configure en_US.UTF-8 locale?" && setup_locale
    ask "Set zsh as default shell?" && setup_default_shell

    success "Done!"
}

main "$@"
