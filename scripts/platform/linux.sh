#!/usr/bin/env bash
# Optional Linux / WSL setup.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "${BASH_SOURCE[0]%/*}/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"

DISTRO_ID=""
DISTRO_LIKE=""

# Persist LANG via localectl, falling back to /etc/locale.conf when localectl
# is missing or fails (e.g. non-systemd WSL).
persist_locale_with_systemd() {
    if command -v localectl >/dev/null 2>&1 && sudo localectl set-locale LANG=en_US.UTF-8; then
        return 0
    fi

    warn "localectl unavailable or failed; writing /etc/locale.conf directly"
    printf '%s\n' "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf >/dev/null
}

# Read ID/ID_LIKE from /etc/os-release into DISTRO_ID/DISTRO_LIKE globals.
load_linux_release_info() {
    DISTRO_ID=""
    DISTRO_LIKE=""

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-}"
        DISTRO_LIKE="${ID_LIKE:-}"
    fi
}

# Map the distro to debian/redhat/arch/suse for locale setup.
distro_family() {
    case "$DISTRO_ID" in
        debian | ubuntu)
            printf 'debian\n'
            return 0
            ;;
        fedora | opensuse* | suse)
            printf 'redhat\n'
            return 0
            ;;
        arch)
            printf 'arch\n'
            return 0
            ;;
    esac
    case "$DISTRO_LIKE" in
        *debian*) printf 'debian\n' ;;
        *rhel* | *fedora* | *suse*) printf 'redhat\n' ;;
        *arch*) printf 'arch\n' ;;
        *) return 1 ;;
    esac
}

# Install the en_US.UTF-8 locale for the given distro family.
install_locale_for_family() {
    case "$1" in
        debian)
            command -v apt-get >/dev/null 2>&1 || {
                warn "apt-get not found; skipping locale install"
                return 0
            }
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
            elif command -v zypper >/dev/null 2>&1; then
                sudo zypper install -y glibc-locale
            else
                warn "dnf/yum/zypper not found; skipping locale install"
                return 0
            fi
            success "Locale en_US.UTF-8 installed"
            ;;
        arch)
            [[ -f /etc/locale.gen ]] || {
                warn "/etc/locale.gen not found; skipping locale generation"
                return 0
            }
            sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
            sudo locale-gen
            success "Locale en_US.UTF-8 generated"
            ;;
    esac
}

# Persist LANG only. LC_ALL overrides every locale category and is meant for
# one-off commands. --reset and localectl also clear an old LC_ALL.
persist_locale_for_family() {
    if [[ "$1" == "debian" ]] && command -v update-locale >/dev/null 2>&1; then
        sudo update-locale --reset LANG=en_US.UTF-8
    else
        persist_locale_with_systemd
    fi
}

# Persist the locale even if it was already generated.
ensure_locale() {
    load_linux_release_info

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

# Print the current login shell basename ($SHELL is stale until re-login).
current_login_shell() {
    local shell_path="" user_name=""

    user_name="${USER:-}"
    if [[ -z "$user_name" ]]; then
        user_name="$(id -un 2>/dev/null)"
    fi
    if command -v getent >/dev/null 2>&1 && [[ -n "$user_name" ]]; then
        shell_path="$(getent passwd "$user_name" 2>/dev/null | awk -F: '{print $7}')"
    fi
    if [[ -z "$shell_path" ]]; then
        shell_path="${SHELL:-}"
    fi
    printf '%s\n' "${shell_path##*/}"
}

ensure_zsh_shell() {
    local zsh_path=""

    zsh_path="$(command -v zsh)" || {
        warn "zsh not installed"
        return 0
    }

    if [[ "$(current_login_shell)" == "zsh" ]]; then
        info "Shell is already zsh"
        return 0
    fi

    info "Changing default shell to zsh..."
    grep -Fxq -- "$zsh_path" /etc/shells 2>/dev/null || printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null

    if chsh -s "$zsh_path"; then
        success "Default shell changed to zsh (log out and back in to apply)"
    else
        error "Failed to change shell"
        return 1
    fi
}

main() {
    require_platform linux

    info "Linux / WSL setup"

    offer "Configure en_US.UTF-8 locale?" ensure_locale
    offer "Set zsh as the default shell?" ensure_zsh_shell

    success "Linux / WSL setup complete"
}

main "$@"
