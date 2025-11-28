#!/usr/bin/env bash
#
# Platform detection, package manager helpers, and core package installation.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$SCRIPT_DIR}"
PACKAGES_JSON="${PACKAGES_JSON:-$SCRIPTS_DIR/packages.json}"

APT_UPDATED="false"
PLATFORM=""

detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            PLATFORM="wsl"
        else
            PLATFORM="linux"
        fi
    else
        PLATFORM="unknown"
    fi

    log_info "Detected platform: $PLATFORM"
}

ensure_package_manager() {
    case "$PLATFORM" in
        macos)
            ensure_homebrew
            ;;
        linux|wsl)
            ensure_apt
            ;;
        *)
            die "Unsupported platform detected: $PLATFORM"
            ;;
    esac
}

ensure_homebrew() {
    if command_exists brew; then
        log_info "Homebrew already available"
        return
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew ready"
}

ensure_apt() {
    if [[ "$APT_UPDATED" == "true" ]]; then
        log_info "APT already updated this session"
        return
    fi

    log_info "Updating APT repositories..."
    sudo apt update
    APT_UPDATED="true"
}

platform_install_with_manager() {
    local manager="$1"
    shift

    if [[ $# -eq 0 ]]; then
        return
    fi

    if [[ "$manager" == "brew" ]]; then
        log_info "Installing ${*} via Homebrew"
        brew install "$@"
    else
        log_info "Installing ${*} via APT"
        sudo apt install -y "$@"
    fi
}

install_core_packages() {
    log_info "Installing core packages via platform package manager"

    ensure_jq_installed

    local manager_key
    case "$PLATFORM" in
        macos)
            manager_key="brew"
            ;;
        linux|wsl)
            manager_key="apt"
            ;;
        *)
            die "Cannot install core packages; unsupported platform $PLATFORM"
            ;;
    esac

    if [[ ! -f "$PACKAGES_JSON" ]]; then
        die "packages.json not found at $PACKAGES_JSON"
    fi

    core_entries=()
    while IFS= read -r entry; do
        core_entries+=("$entry")
    done < <(
        jq -r --arg manager "$manager_key" '
            .packages[]
            | select(.name != "jq")
            | .[$manager]
            | select(. != null and . != "")
        ' "$PACKAGES_JSON"
    )

    local -a regular_packages=()
    local -a cask_packages=()

    for entry in "${core_entries[@]}"; do
        if [[ "$entry" =~ ^--cask[[:space:]]+(.+)$ ]]; then
            # Extract package name after --cask and any whitespace
            cask_packages+=("${BASH_REMATCH[1]}")
        else
            regular_packages+=("$entry")
        fi
    done

    if [[ ${#regular_packages[@]} -gt 0 ]]; then
        platform_install_with_manager "$manager_key" "${regular_packages[@]}"
    fi
    
    if [[ "$manager_key" == "brew" ]] && [[ ${#cask_packages[@]} -gt 0 ]]; then
        log_info "Installing cask packages: ${cask_packages[*]}"
        brew install --cask "${cask_packages[@]}"
    fi
    
    if [[ ${#regular_packages[@]} -eq 0 ]] && [[ ${#cask_packages[@]} -eq 0 ]]; then
        log_info "No additional core packages configured for $manager_key"
    fi
}

ensure_jq_installed() {
    if command_exists jq; then
        log_info "jq already available"
        return
    fi

    log_info "Installing jq to parse packages.json"
    case "$PLATFORM" in
        macos)
            brew install jq
            ;;
        linux|wsl)
            sudo apt install -y jq
            ;;
        *)
            die "Cannot install jq on platform $PLATFORM"
            ;;
    esac
}

apply_platform_tweaks() {
    case "$PLATFORM" in
        macos)
            log_info "Running macOS-specific tweaks"
            bash "$SCRIPTS_DIR/tweaks/macos-tweaks.sh"
            ;;
        wsl)
            log_info "Running WSL-specific tweaks"
            bash "$SCRIPTS_DIR/tweaks/wsl-tweaks.sh"
            ;;
        linux)
            log_info "Running Linux-specific tweaks"
            bash "$SCRIPTS_DIR/tweaks/linux-tweaks.sh"
            ;;
        *)
            log_warning "Skipping platform tweaks for $PLATFORM"
            ;;
    esac
}
