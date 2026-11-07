#!/usr/bin/env bash
# Read-only macOS state checks shared by the setup and doctor scripts.

# Guard against double-sourcing: macos.sh sources both this file and
# macos-preflight.sh (which sources this file again). Reassigning a readonly
# would abort under `set -e`.
[[ -n "${__DOTFILES_MACOS_STATE_LOADED:-}" ]] && return 0
__DOTFILES_MACOS_STATE_LOADED=1

MACOS_FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"
readonly MACOS_FIREWALL
XCODE_APP="${XCODE_APP:-/Applications/Xcode.app}"
readonly XCODE_APP
# Backs System Settings > Spotlight > Search Privacy. Root-only.
MACOS_SPOTLIGHT_CONFIG="/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist"
# shellcheck disable=SC2034 # read by macos.sh
readonly MACOS_SPOTLIGHT_CONFIG

# High-churn dev paths to keep out of Spotlight, one per line. Callers set the
# XDG variables first. Only paths that exist are excluded.
macos_spotlight_exclusion_paths() {
    printf '%s\n' \
        "$HOME/Code" \
        "$HOME/Work" \
        "$XDG_CACHE_HOME" \
        "$XDG_DATA_HOME/gradle" \
        "$XDG_DATA_HOME/pnpm" \
        "$XDG_CONFIG_HOME/.android" \
        "$HOME/.t3" \
        "$HOME/.codex" \
        "${ANDROID_HOME:-$HOME/Library/Android/sdk}" \
        "$HOME/Library/Caches" \
        "$HOME/Library/Developer/CoreSimulator" \
        "$HOME/Library/Developer/Xcode/DerivedData" \
        "$HOME/Library/Application Support/Code" \
        "$HOME/Library/Application Support/Codex" \
        "$HOME/Library/Application Support/t3code-v2" \
        "$HOME/Library/Python" \
        "$HOME/Library/Application Support/Firefox" \
        "$HOME/Library/Application Support/LibreOffice" \
        "$HOME/Library/Containers/com.microsoft.teams2" \
        "$HOME/Library/Group Containers/UBF8T346G9.Office" \
        "$HOME/Library/Containers/com.microsoft.Excel" \
        "$HOME/Library/Containers/com.microsoft.Outlook" \
        "$HOME/Library/Containers/com.microsoft.Powerpoint" \
        "$HOME/Library/Containers/com.microsoft.Word" \
        "$HOME/Library/Containers/com.microsoft.teams2.agent" \
        "$HOME/Library/Group Containers/UBF8T346G9.com.microsoft.teams" \
        "$HOME/Library/Containers/com.microsoft.entrabroker.BrokerApp" \
        "$HOME/Library/Containers/net.whatsapp.WhatsApp" \
        "$HOME/Library/Containers/net.whatsapp.WhatsApp.ServiceExtension" \
        "$HOME/Library/Application Support/com.colliderli.iina"
}

# Every item Spotlight has indexed under $HOME, one path per line. Scoping
# mdfind to a sandbox container returns nothing, so callers filter this
# listing instead.
macos_spotlight_indexed_home() {
    mdfind -onlyin "$HOME" 'kMDItemContentTypeTree == "public.item"' 2>/dev/null
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
