#!/usr/bin/env bash
#
# macOS-only helpers shared by the platform scripts and doctor.sh.
#
# scripts/lib/common.sh stays cross-platform; anything that shells out to a
# macOS-specific binary lives here instead. Read-only: nothing in this file
# changes system state.
#

# Guard against double-sourcing: macos.sh sources this, then invokes
# macos-hardening.sh, which sources it again.
if [[ -n "${_DOTFILES_MACOS_COMMON_LOADED:-}" ]]; then
    return 0
fi
_DOTFILES_MACOS_COMMON_LOADED=1

MACOS_FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"

# True when the Mac is enrolled in MDM (Intune, Jamf, Kandji, ...).
#
# This matters because a managed Mac silently refuses or reverts several of the
# settings this repo writes:
#   - socketfilterfw prints "Firewall settings cannot be modified from command
#     line on managed Mac computers" and still exits 0, so a naive caller
#     reports success after changing nothing.
#   - A configuration profile outranks `defaults write`, and re-applies its own
#     values on its own schedule.
# Callers use this to explain a no-op rather than claim a change that did not
# happen.
macos_mdm_managed() {
    profiles status -type enrollment 2>/dev/null | grep -qi 'MDM enrollment: Yes'
}

macos_firewall_available() {
    [[ -x "$MACOS_FIREWALL" ]]
}

# Reads work on managed Macs even though writes do not, so this stays reliable
# everywhere.
macos_firewall_enabled() {
    macos_firewall_available || return 1
    "$MACOS_FIREWALL" --getglobalstate 2>/dev/null | grep -q "enabled"
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

# Automatic install of XProtect / Gatekeeper data and Rapid Security Responses.
# These are on by default; the check exists so a machine that drifted (or was
# "optimised" by a guide) is caught by `make doctor`.
macos_security_updates_automatic() {
    local domain="/Library/Preferences/com.apple.SoftwareUpdate" key=""

    for key in ConfigDataInstall CriticalUpdateInstall; do
        [[ "$(defaults read "$domain" "$key" 2>/dev/null)" == "1" ]] || return 1
    done
}
