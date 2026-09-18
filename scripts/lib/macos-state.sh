#!/usr/bin/env bash
# Read-only macOS state probes shared by the setup and doctor scripts.

MACOS_FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"
XCODE_APP="${XCODE_APP:-/Applications/Xcode.app}"

# A managed Mac may reject or later revert a setting the command reported as applied.
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
