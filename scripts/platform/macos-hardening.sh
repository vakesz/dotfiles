#!/usr/bin/env bash
# Optional macOS hardening, drawn from drduh/macOS-Security-and-Privacy-Guide.

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"

enable_firewall() {
    if macos_mdm_managed; then
        warn "This Mac is MDM-managed; socketfilterfw refuses command-line changes"
        info "The firewall is set by your management profile, not by this script"
        return 1
    fi

    info "Enabling the application firewall..."
    sudo -v

    sudo "$MACOS_FIREWALL" --setglobalstate on >/dev/null
    sudo "$MACOS_FIREWALL" --setloggingmode on >/dev/null

    sudo pkill -HUP socketfilterfw 2>/dev/null || true

    # socketfilterfw exits 0 even when it changed nothing, so verify.
    if ! macos_firewall_enabled; then
        error "Firewall still reports disabled after the change"
        return 1
    fi

    success "Firewall enabled"
}

# Signed apps otherwise accept incoming connections without a prompt.
disable_firewall_signed_allowlist() {
    if macos_mdm_managed; then
        warn "This Mac is MDM-managed; socketfilterfw refuses command-line changes"
        info "Change it in System Settings > Network > Firewall > Options or through the management profile"
        return 1
    fi

    info "Stopping the firewall from allowing signed software automatically..."
    sudo -v
    sudo "$MACOS_FIREWALL" --setallowsigned off >/dev/null
    sudo "$MACOS_FIREWALL" --setallowsignedapp off >/dev/null
    sudo pkill -HUP socketfilterfw 2>/dev/null || true

    # socketfilterfw exits 0 even when it changed nothing, so verify.
    if ! macos_firewall_signed_allowlist_off; then
        error "The firewall still allows signed software automatically"
        return 1
    fi

    success "The firewall now asks before signed software accepts connections"
}

enable_firewall_stealth_mode() {
    if macos_mdm_managed; then
        warn "This Mac is MDM-managed; socketfilterfw refuses command-line changes"
        info "Set Firewall Stealth Mode in System Settings or through the management profile"
        return 1
    fi

    if ! macos_firewall_enabled; then
        error "Enable the application firewall before enabling Stealth Mode"
        return 1
    fi

    info "Enabling Firewall Stealth Mode..."
    sudo -v
    sudo "$MACOS_FIREWALL" --setstealthmode on >/dev/null
    sudo pkill -HUP socketfilterfw 2>/dev/null || true

    # socketfilterfw exits 0 even when it changed nothing, so verify.
    if ! macos_firewall_stealth_mode_enabled; then
        error "Firewall Stealth Mode still reports disabled after the change"
        return 1
    fi

    success "Firewall Stealth Mode enabled"
}

disable_remote_login() {
    info "Disabling remote login (SSH server)..."
    sudo -v

    # -f skips systemsetup's own stdin confirmation.
    sudo systemsetup -f -setremotelogin off >/dev/null || {
        warn "Could not change remote login; grant Full Disk Access to your terminal"
        return 1
    }
    success "Remote login disabled"
}

disable_remote_services() {
    local failed=0

    info "Disabling Screen Sharing and Remote Apple Events..."
    sudo -v

    sudo systemsetup -f -setremoteappleevents off >/dev/null 2>&1 || {
        warn "Could not change Remote Apple Events; grant Full Disk Access to your terminal"
        failed=1
    }

    sudo launchctl bootout system/com.apple.screensharing 2>/dev/null || true
    # `disable` persists across reboots; `bootout` alone does not.
    sudo launchctl disable system/com.apple.screensharing 2>/dev/null || {
        warn "Could not persistently disable Screen Sharing"
        failed=1
    }

    if ((failed)); then
        error "One or more remote services could not be disabled"
        return 1
    fi

    success "Screen Sharing and Remote Apple Events disabled"
}

remote_management_off() {
    ! macos_remote_management_active
}

disable_remote_management() {
    local kickstart="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"

    [[ -x "$kickstart" ]] || {
        warn "ARD kickstart not found at $kickstart"
        return 1
    }

    info "Turning off Remote Management..."
    sudo -v
    sudo "$kickstart" -deactivate -configure -access -off >/dev/null
    sudo "$kickstart" -deactivate -stop >/dev/null

    if macos_remote_management_active; then
        error "Remote Management is still running after the change"
        return 1
    fi

    success "Remote Management turned off"
}

auto_login_off() {
    ! macos_auto_login_enabled
}

disable_auto_login() {
    info "Turning off automatic login..."
    sudo -v
    sudo sysadminctl -autologin off

    if macos_auto_login_enabled; then
        error "Automatic login still reports enabled after the change"
        return 1
    fi

    success "Automatic login turned off"
}

# The status wording for "immediate" isn't documented, so accept either form.
# A profile that sets the delay wins over sysadminctl, so a managed delay
# counts as settled; otherwise this step would be offered on every run.
screen_lock_settled() {
    local status=""

    if macos_managed_pref_set com.apple.screensaver askForPasswordDelay; then
        return 0
    fi
    status="$(sysadminctl -screenLock status 2>&1)" || return 1
    [[ "$status" == *immediate* || "$status" == *"delay is 0 seconds"* ]]
}

# macOS 13 and later ignore the old com.apple.screensaver askForPassword keys.
require_password_immediately() {
    info "Requiring your password as soon as the screen locks (sysadminctl asks for it)..."
    sysadminctl -screenLock immediate -password - || return 1
    info "Now: $(sysadminctl -screenLock status 2>&1 | sed 's/^.*\] //')"
    if macos_mdm_managed; then
        warn "This Mac is MDM-managed; a profile can override the screen lock delay"
    fi
}

enable_gatekeeper() {
    info "Enabling Gatekeeper..."
    sudo -v
    sudo spctl --global-enable || true

    if ! macos_gatekeeper_enabled; then
        error "Gatekeeper still reports disabled"
        info "Turn it on in System Settings > Privacy & Security > Security"
        return 1
    fi

    success "Gatekeeper enabled"
}

apply_privacy_defaults() {
    info "Applying privacy defaults..."

    defaults write com.apple.CrashReporter DialogType -string none
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false

    sudo -v
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder \
        NoMulticastAdvertisements -bool true

    sudo defaults write \
        "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" \
        AutoSubmit -bool false
    sudo defaults write \
        "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" \
        ThirdPartyDataSubmit -bool false

    success "Privacy defaults applied"
}

enable_security_updates() {
    local key=""

    # Only XProtect data and Rapid Security Responses; topgrade handles OS
    # updates. Those two install nothing unless macOS also checks for and
    # downloads updates automatically.
    info "Enabling automatic security responses and system data files..."
    sudo -v

    for key in AutomaticCheckEnabled AutomaticDownload ConfigDataInstall CriticalUpdateInstall; do
        sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate "$key" -bool true
    done

    if ! macos_automatic_security_updates_enabled; then
        error "Automatic security responses still report disabled after the change"
        return 1
    fi

    success "Automatic security responses enabled"
}

enable_filevault() {
    if ! is_interactive; then
        info "Non-interactive shell; skipping FileVault"
        return 0
    fi

    # Unlike SIP, FileVault doesn't need Recovery. The key is printed rather
    # than written to a file: a plaintext key file in $HOME is worse than
    # terminal scrollback.
    warn "This prints a personal recovery key ONCE. Store it in your password manager right away."
    info "Encryption then runs in the background; the Mac stays usable."

    sudo -v
    sudo fdesetup enable -user "$USER" || {
        warn "FileVault was not enabled"
        return 1
    }

    success "FileVault enabled"
    warn "Once the recovery key is in your password manager, clear the terminal scrollback (Cmd+K in Ghostty or Terminal)."
}

homebrew_analytics_disabled() {
    brew analytics state 2>/dev/null | grep -qi "disabled"
}

disable_homebrew_analytics() {
    # The shell exports HOMEBREW_NO_ANALYTICS; this covers everywhere else.
    info "Opting out of Homebrew analytics..."
    brew analytics off
    success "Homebrew analytics disabled"
}

# Print "  label: on|off" for the check function $2.
report_state() {
    if "$2"; then
        printf '  %s: on\n' "$1"
    else
        printf '  %s: off\n' "$1"
    fi
}

report_protection_status() {
    info "Current protection status:"

    if has_command fdesetup; then
        printf '  FileVault: %s\n' "$(fdesetup status 2>/dev/null || printf 'unknown')"
    fi

    if has_command csrutil; then
        printf '  %s\n' "$(csrutil status 2>/dev/null || printf 'SIP: unknown')"
    fi

    if has_command spctl; then
        printf '  Gatekeeper: %s\n' "$(spctl --status 2>&1 || printf 'unknown')"
    fi

    # Reported only; turn these off in System Settings > General > Sharing.
    report_state "File Sharing" macos_file_sharing_enabled
    report_state "Printer Sharing" macos_printer_sharing_enabled
    report_state "Internet Sharing" macos_internet_sharing_enabled
    report_state "Media Sharing" macos_media_sharing_enabled

    if macos_mdm_managed; then
        warn "This Mac is MDM-managed; a configuration profile can override anything set here"
    fi

    info "SIP is changed from Recovery, not from this script"
}

main() {
    require_platform macos

    info "macOS hardening (optional)"

    confirm "Apply optional macOS hardening now?" || {
        info "Skipping macOS hardening"
        return 0
    }

    report_protection_status

    if macos_firewall_available; then
        offer_if_missing "Enable the application firewall?" macos_firewall_enabled enable_firewall "Firewall already enabled"
        offer_if_missing "Enable Firewall Stealth Mode?" macos_firewall_stealth_mode_enabled enable_firewall_stealth_mode "Firewall Stealth Mode already enabled"
        offer_if_missing "Make the firewall ask before signed software accepts connections?" macos_firewall_signed_allowlist_off disable_firewall_signed_allowlist "Firewall already asks about signed software"
    else
        warn "socketfilterfw not found; skipping firewall"
    fi

    offer_if_missing "Enable FileVault now (prints a recovery key you must save)?" macos_filevault_enabled enable_filevault "FileVault already enabled"
    offer_if_missing "Enable Gatekeeper?" macos_gatekeeper_enabled enable_gatekeeper "Gatekeeper already enabled"
    offer_if_missing "Turn off automatic login?" auto_login_off disable_auto_login "Automatic login already off"
    offer_if_missing "Require your password immediately after the screen locks?" screen_lock_settled require_password_immediately "Screen lock delay already immediate or set by a profile"

    offer "Disable remote login (SSH server)?" disable_remote_login
    offer "Disable Screen Sharing and Remote Apple Events (breaks IT remote assistance)?" disable_remote_services
    offer_if_missing "Turn off Remote Management (breaks IT remote assistance)?" remote_management_off disable_remote_management "Remote Management already off"
    offer "Apply privacy defaults (crash reports, ads, analytics, iCloud, Bonjour)?" apply_privacy_defaults

    offer_if_missing "Check for updates and auto-install security responses and system data files?" macos_automatic_security_updates_enabled enable_security_updates "Automatic security responses already enabled"

    require_command brew "the Homebrew analytics opt-out" && offer_if_missing "Opt out of Homebrew analytics?" homebrew_analytics_disabled disable_homebrew_analytics "Homebrew analytics already disabled"

    success "macOS hardening complete"
}

main "$@"
