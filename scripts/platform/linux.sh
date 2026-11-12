#!/usr/bin/env bash
# Optional Linux / WSL setup.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"

# CLI tools from the Brewfile, one row each:
#   tool|commands|apt-get|dnf|zypper|pacman|upstream install page
# commands: any one on PATH means installed ("-" = check the package instead).
# Package fields list alternatives, first available wins; "-" = never install
# from that repo. Whether a repo carries a name is probed at install time, so
# an older release that lacks a package just falls through to the hint.
readonly -a CLI_TOOL_ROWS=(
    "bat|bat batcat|bat|bat|bat|bat|https://github.com/sharkdp/bat#installation"
    "bun|bun|bun|bun|bun|bun|https://bun.sh/docs/installation"
    "ccache|ccache|ccache|ccache|ccache|ccache|https://ccache.dev/download.html"
    "direnv|direnv|direnv|direnv|direnv|direnv|https://direnv.net/docs/installation.html"
    "eza|eza|eza|eza|eza|eza|https://github.com/eza-community/eza/blob/main/INSTALL.md"
    "fd|fd fdfind|fd-find|fd-find|fd|fd|https://github.com/sharkdp/fd#installation"
    "fzf|fzf|fzf|fzf|fzf|fzf|https://github.com/junegunn/fzf#installation"
    "git-lfs|git-lfs|git-lfs|git-lfs|git-lfs|git-lfs|https://git-lfs.com"
    "jq|jq|jq|jq|jq|jq|https://jqlang.org/download/"
    # Debian/Ubuntu ship an end-of-life node (18 on Ubuntu 24.04, 12 on 22.04).
    "node|node|-|nodejs|-|nodejs|https://nodejs.org/en/download (fnm or NodeSource)"
    "pnpm|pnpm|pnpm|pnpm|pnpm|pnpm|https://pnpm.io/installation"
    "ripgrep|rg|ripgrep|ripgrep|ripgrep|ripgrep|https://github.com/BurntSushi/ripgrep#installation"
    # Fedora's package ships only rustup-init; running it installs rustup.
    "rustup|rustup rustup-init|rustup|rustup|rustup|rustup|https://rustup.rs"
    "starship|starship|starship|starship|starship|starship|https://starship.rs/guide/#step-1-install-starship"
    "tealdeer|tldr|tealdeer tldr|tealdeer tldr|tealdeer|tealdeer|https://tealdeer-rs.github.io/tealdeer/installing.html"
    "uv|uv|uv|uv|uv|uv|https://docs.astral.sh/uv/getting-started/installation/"
    # The Brewfile's yq is mikefarah's. Debian's yq package is an unrelated
    # Python jq wrapper with a different CLI; Arch ships mikefarah's as go-yq.
    "yq|yq|-|yq|yq|go-yq|https://github.com/mikefarah/yq#install"
    "zoxide|zoxide|zoxide|zoxide|zoxide|zoxide|https://github.com/ajeetdsouza/zoxide#installation"
    "zsh-autosuggestions|-|zsh-autosuggestions|zsh-autosuggestions|zsh-autosuggestions|zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md"
    "zsh-syntax-highlighting|-|zsh-syntax-highlighting|zsh-syntax-highlighting|zsh-syntax-highlighting|zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md"
)

# Run "$@" as root: directly when already root (containers, root WSL), else
# through sudo.
as_root() {
    if ((EUID == 0)); then
        "$@"
        return
    fi
    command -v sudo >/dev/null 2>&1 || {
        error "sudo not found; rerun as root or install sudo"
        return 1
    }
    sudo "$@"
}

# True under WSL. WSL_DISTRO_NAME is unset under sudo, so also check the kernel.
is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

# Print the first supported package manager on PATH. Dispatching on the tool
# rather than the distro name covers derivatives without a lookup table.
package_manager() {
    local pm=""
    for pm in apt-get dnf zypper pacman; do
        command -v "$pm" >/dev/null 2>&1 && {
            printf '%s\n' "$pm"
            return 0
        }
    done
    return 1
}

# Install packages "$@" with package manager $1.
pkg_install() {
    local pm="$1"
    shift
    case "$pm" in
        apt-get) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        dnf) as_root dnf install -y "$@" ;;
        zypper) as_root zypper --non-interactive install "$@" ;;
        # No -y: syncing without upgrading would make this a partial upgrade.
        pacman) as_root pacman -S --needed --noconfirm "$@" ;;
    esac
}

# True when package $2 exists in the repos of package manager $1.
pkg_available() {
    local policy=""
    case "$1" in
        apt-get)
            policy="$(apt-cache policy "$2" 2>/dev/null)"
            [[ "$policy" =~ Candidate:\ [^\(] ]]
            ;;
        dnf) dnf -q info "$2" >/dev/null 2>&1 ;;
        zypper) zypper --non-interactive --quiet search --match-exact "$2" >/dev/null 2>&1 ;;
        pacman) pacman -Si "$2" >/dev/null 2>&1 ;;
    esac
}

# True when package $2 is installed according to package manager $1.
pkg_installed() {
    case "$1" in
        apt-get) [[ "$(dpkg-query -W -f='${Status}' "$2" 2>/dev/null)" == "install ok installed" ]] ;;
        dnf | zypper) rpm -q "$2" >/dev/null 2>&1 ;;
        pacman) pacman -Q "$2" >/dev/null 2>&1 ;;
    esac
}

# Uncomment en_US.UTF-8 in /etc/locale.gen and regenerate. Debian's locale-gen
# ignores arguments, so `locale-gen en_US.UTF-8` silently generates nothing.
generate_locale_from_locale_gen() {
    [[ -f /etc/locale.gen ]] || {
        warn "/etc/locale.gen not found; skipping locale generation"
        return 0
    }
    as_root sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen || printf '%s\n' "en_US.UTF-8 UTF-8" | as_root tee -a /etc/locale.gen >/dev/null
    as_root locale-gen
}

# Install the en_US.UTF-8 locale with package manager $1.
install_locale() {
    case "$1" in
        apt-get)
            as_root apt-get update -qq
            pkg_install apt-get locales
            generate_locale_from_locale_gen
            ;;
        dnf) pkg_install dnf glibc-langpack-en ;;
        zypper) pkg_install zypper glibc-locale ;;
        pacman) generate_locale_from_locale_gen ;;
    esac
    success "Locale en_US.UTF-8 installed"
}

# Persist LANG via localectl, falling back to /etc/locale.conf when localectl
# is missing or fails (e.g. non-systemd WSL, containers).
persist_locale_conf() {
    if command -v localectl >/dev/null 2>&1 && as_root localectl set-locale LANG=en_US.UTF-8; then
        return 0
    fi

    warn "localectl unavailable or failed; writing /etc/locale.conf directly"
    printf '%s\n' "LANG=en_US.UTF-8" | as_root tee /etc/locale.conf >/dev/null
}

# Persist LANG only. LC_ALL overrides every locale category and is meant for
# one-off commands. --reset and localectl also clear an old LC_ALL.
persist_locale() {
    if [[ "$1" == "apt-get" ]] && command -v update-locale >/dev/null 2>&1; then
        as_root update-locale --reset LANG=en_US.UTF-8
    else
        persist_locale_conf
    fi
}

# Persist the locale even if it was already generated.
ensure_locale() {
    local pm=""
    pm="$(package_manager)" || {
        warn "No supported package manager (apt-get, dnf, zypper, pacman); skipping locale setup"
        return 0
    }

    if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
        info "Locale en_US.UTF-8 already available"
    else
        info "Installing en_US.UTF-8 locale..."
        install_locale "$pm"
    fi

    persist_locale "$pm"
    success "LANG=en_US.UTF-8 persisted"
}

# True when tool row fields say it is already installed: one of the commands
# $2 is on PATH, or (for command-less rows) one of the packages $3 is installed.
tool_installed() {
    local pm="$1" commands="$2" packages="$3" name=""

    if [[ "$commands" != "-" ]]; then
        for name in $commands; do
            command -v "$name" >/dev/null 2>&1 && return 0
        done
        return 1
    fi

    [[ "$packages" != "-" ]] || return 1
    for name in $packages; do
        pkg_installed "$pm" "$name" && return 0
    done
    return 1
}

# Install every CLI tool the package manager carries; list the rest with
# their upstream install page. Nothing outside the distro repos is run.
install_cli_tools() {
    local pm="" row="" tool="" commands="" apt="" dnf="" zypper="" pacman="" hint=""
    local packages="" candidate="" chosen="" pkg=""
    local -a to_install=() missing=()

    pm="$(package_manager)" || {
        warn "No supported package manager (apt-get, dnf, zypper, pacman); skipping CLI tools"
        return 0
    }

    # apt-cache answers from the local index, which is empty on fresh images.
    [[ "$pm" == "apt-get" ]] && as_root apt-get update -qq

    for row in "${CLI_TOOL_ROWS[@]}"; do
        IFS='|' read -r tool commands apt dnf zypper pacman hint <<<"$row"
        case "$pm" in
            apt-get) packages="$apt" ;;
            dnf) packages="$dnf" ;;
            zypper) packages="$zypper" ;;
            pacman) packages="$pacman" ;;
        esac

        tool_installed "$pm" "$commands" "$packages" && continue

        chosen=""
        if [[ "$packages" != "-" ]]; then
            for candidate in $packages; do
                pkg_available "$pm" "$candidate" && {
                    chosen="$candidate"
                    break
                }
            done
        fi

        if [[ -n "$chosen" ]]; then
            to_install+=("$chosen")
        else
            missing+=("$tool|$hint")
        fi
    done

    if ((${#to_install[@]} == 0)); then
        info "No CLI tools to install with $pm"
    else
        info "Installing with $pm: ${to_install[*]}"
        # One transaction is fastest; if it fails, retry one by one so a single
        # broken package doesn't block the rest.
        if ! pkg_install "$pm" "${to_install[@]}"; then
            warn "Batch install failed; retrying packages one at a time"
            # pacman -S without -y can't resolve dependencies on an out-of-date system.
            [[ "$pm" == "pacman" ]] && info "If pacman reports dependency errors, run 'sudo pacman -Syu' first"
            for pkg in "${to_install[@]}"; do
                pkg_install "$pm" "$pkg" || {
                    warn "Could not install $pkg"
                    missing+=("$pkg|see the error above")
                }
            done
        fi
    fi

    if ((${#missing[@]} == 0)); then
        success "All CLI tools are installed"
        return 0
    fi

    warn "Not available from $pm; install these from upstream if you want them:"
    for row in "${missing[@]}"; do
        printf '  %-24s %s\n' "${row%%|*}" "${row#*|}" >&2
    done
    info "Run 'make doctor' afterwards to see what is still missing"
}

# Print gitconfig.local, the untracked machine-local file config/git/config
# includes.
git_local_config_path() {
    printf '%s\n' "$XDG_CONFIG_HOME/git/gitconfig.local"
}

# True when HTTPS auth is already handled: Git Credential Manager is on PATH,
# or gitconfig.local already sets a helper, which is never overwritten.
credential_helper_configured() {
    command -v git-credential-manager >/dev/null 2>&1 && return 0
    command -v git >/dev/null 2>&1 || return 1
    git config --file "$(git_local_config_path)" --get-all credential.helper >/dev/null 2>&1
}

# Print the Windows-side Git Credential Manager under WSL, if installed.
# Git for Windows moved it from libexec/git-core to bin in 2.39.
windows_gcm_path() {
    local candidate=""
    is_wsl || return 1
    for candidate in \
        "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe" \
        "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"; do
        [[ -f "$candidate" ]] && {
            printf '%s\n' "$candidate"
            return 0
        }
    done
    return 1
}

# Print the helper value to use: Windows GCM under WSL, then libsecret when a
# keyring is reachable over D-Bus, else the in-memory cache. Never `store`,
# which keeps passwords in plaintext.
choose_credential_helper() {
    local gcm=""

    if gcm="$(windows_gcm_path)"; then
        # Git runs an absolute-path helper through the shell, so escape spaces.
        printf '%s\n' "${gcm// /\\ }"
    elif [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" && -x "$(git --exec-path)/git-credential-libsecret" ]]; then
        printf '%s\n' "libsecret"
    else
        printf '%s\n' "cache --timeout=3600"
    fi
}

# config/git/config sets helper = manager, which fails on every HTTPS operation
# without GCM. Add a reset plus a working helper to gitconfig.local.
configure_git_credential_helper() {
    local file="" helper=""

    require_command git "git credential helper setup" || return 0

    file="$(git_local_config_path)"
    helper="$(choose_credential_helper)"

    mkdir -p "${file%/*}"
    # --add appends, so other settings already in the file are kept. The empty
    # value clears the helper list inherited from config/git/config.
    git config --file "$file" --add credential.helper ""
    git config --file "$file" --add credential.helper "$helper"
    success "Git credential helper set to '$helper' in $file"

    if [[ "$helper" == cache* ]]; then
        info "Credentials stay in memory for an hour. To keep them on disk in plaintext instead:"
        info "  git config --file \"$file\" --replace-all credential.helper store '^cache'"
    fi
}

ensure_zsh_shell() {
    local zsh_path=""

    zsh_path="$(command -v zsh)" || {
        warn "zsh not installed"
        return 0
    }

    if [[ "$(login_shell_name)" == "zsh" ]]; then
        info "Shell is already zsh"
        return 0
    fi

    info "Changing default shell to zsh..."
    grep -Fxq -- "$zsh_path" /etc/shells 2>/dev/null || printf '%s\n' "$zsh_path" | as_root tee -a /etc/shells >/dev/null

    if chsh -s "$zsh_path"; then
        success "Default shell changed to zsh (log out and back in to apply)"
    else
        error "Failed to change shell"
        return 1
    fi
}

main() {
    require_platform linux
    set_xdg_environment_defaults

    info "Linux / WSL setup"

    offer "Configure en_US.UTF-8 locale?" ensure_locale
    offer "Install the CLI tools and zsh plugins with the system package manager?" install_cli_tools
    offer_if_missing "Configure a git credential helper in gitconfig.local?" \
        credential_helper_configured configure_git_credential_helper \
        "Git credential helper already configured"
    offer "Set zsh as the default shell?" ensure_zsh_shell

    success "Linux / WSL setup complete"
}

main "$@"
