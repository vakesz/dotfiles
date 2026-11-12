#!/usr/bin/env bash
# macOS state checks and small helpers shared by the setup and doctor scripts.

# Guard against double-sourcing: macos.sh sources both this file and
# macos-preflight.sh (which sources this file again). Reassigning a readonly
# would abort under `set -e`.
[[ -n "${__DOTFILES_MACOS_STATE_LOADED:-}" ]] && return 0
__DOTFILES_MACOS_STATE_LOADED=1

MACOS_FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"
readonly MACOS_FIREWALL
XCODE_APP="${XCODE_APP:-/Applications/Xcode.app}"
readonly XCODE_APP
# Data lists; DOCK_APPS needs XCODE_APP above. doctor.sh gets
# macos_spotlight_exclusion_paths through this file.
# shellcheck source=scripts/lib/macos-config.sh
source "${BASH_SOURCE[0]%/*}/macos-config.sh"
# Backs System Settings > Spotlight > Search Privacy. Root-only.
MACOS_SPOTLIGHT_CONFIG="/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist"
# shellcheck disable=SC2034 # read by macos.sh
readonly MACOS_SPOTLIGHT_CONFIG

# The generated LaunchAgent that gives GUI apps the ~/.zshenv variables.
LAUNCHD_ENV_LABEL="io.github.vakesz.dotfiles.launchd-env"
readonly LAUNCHD_ENV_LABEL
LAUNCHD_ENV_PLIST="$HOME/Library/LaunchAgents/$LAUNCHD_ENV_LABEL.plist"
# shellcheck disable=SC2034 # read by macos.sh and doctor.sh
readonly LAUNCHD_ENV_PLIST

# Every item Spotlight has indexed under $HOME, one path per line. Scoping
# mdfind to a sandbox container returns nothing, so callers filter this
# listing instead.
macos_spotlight_indexed_home() {
    mdfind -onlyin "$HOME" 'kMDItemContentTypeTree == "public.item"' 2>/dev/null
}

# True on Apple Silicon, including under Rosetta (unlike `uname -m`).
macos_apple_silicon() {
    [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]
}

# Set MACOS_BREW_PREFIX once. Call it in the current shell, never inside $(...),
# or the cache is lost to the subshell. Returns 1 while brew is unavailable.
MACOS_BREW_PREFIX=""
macos_brew_prefix() {
    if [[ -z "$MACOS_BREW_PREFIX" ]]; then
        MACOS_BREW_PREFIX="${HOMEBREW_PREFIX:-}"
    fi
    if [[ -z "$MACOS_BREW_PREFIX" ]]; then
        MACOS_BREW_PREFIX="$(brew --prefix 2>/dev/null)" || MACOS_BREW_PREFIX=""
    fi
    [[ -n "$MACOS_BREW_PREFIX" ]]
}

# True when the generated LaunchAgent is on disk and launchd has it loaded.
macos_launchd_env_agent_loaded() {
    [[ -f "$LAUNCHD_ENV_PLIST" ]] &&
        launchctl print "gui/$(id -u)/$LAUNCHD_ENV_LABEL" >/dev/null 2>&1
}

# On a managed Mac, a profile can reject or later revert a setting that looked applied.
macos_mdm_managed() {
    profiles status -type enrollment 2>/dev/null | grep -qi 'MDM enrollment: Yes'
}

macos_firewall_available() {
    [[ -x "$MACOS_FIREWALL" ]]
}

macos_firewall_enabled() {
    macos_firewall_available || return 1
    "$MACOS_FIREWALL" --getglobalstate 2>/dev/null | grep -q "enabled"
}

macos_firewall_stealth_mode_enabled() {
    macos_firewall_available || return 1
    "$MACOS_FIREWALL" --getstealthmode 2>/dev/null | grep -qi "stealth mode is on"
}

macos_gatekeeper_enabled() {
    spctl --status 2>/dev/null | grep -q "assessments enabled"
}

macos_filevault_enabled() {
    fdesetup status 2>/dev/null | grep -q "FileVault is On"
}

macos_sip_enabled() {
    csrutil status 2>/dev/null | grep -q "enabled"
}

macos_automatic_security_updates_enabled() {
    local domain="/Library/Preferences/com.apple.SoftwareUpdate" key=""

    for key in ConfigDataInstall CriticalUpdateInstall; do
        [[ "$(defaults read "$domain" "$key" 2>/dev/null)" == "1" ]] || return 1
    done
}

macos_touch_id_sudo_enabled() {
    [[ -f /etc/pam.d/sudo_local ]] &&
        grep -qE '^[[:space:]]*auth.*pam_tid\.so' /etc/pam.d/sudo_local
}

macos_xcode_cli_tools_installed() {
    xcode-select -p >/dev/null 2>&1
}

macos_full_xcode_installed() {
    [[ -d "$XCODE_APP" ]] && xcodebuild -version >/dev/null 2>&1
}
