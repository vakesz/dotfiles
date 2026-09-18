#!/usr/bin/env bash
# Optional macOS hardening, drawn from drduh/macOS-Security-and-Privacy-Guide.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../lib/paths.sh"
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

    # Not --setallowsigned off / stealth mode: both break local development.

    sudo pkill -HUP socketfilterfw 2>/dev/null || true

    # socketfilterfw exits 0 even when it declined to do anything.
    if ! macos_firewall_enabled; then
        error "Firewall still reports disabled after the change"
        return 1
    fi

    success "Firewall enabled"
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

    # macOS 13+ drives screen lock from Lock Screen settings and may ignore these.
    defaults write com.apple.screensaver askForPassword -int 1 2>/dev/null || true
    defaults write com.apple.screensaver askForPasswordDelay -int 0 2>/dev/null || true

    success "Privacy defaults applied"
}

enable_security_updates() {
    # Only XProtect data and RSRs; topgrade owns full OS updates.
    info "Enabling automatic security responses and system data files..."
    sudo -v

    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate \
        ConfigDataInstall -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate \
        CriticalUpdateInstall -bool true

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

    # FileVault does not need Recovery; SIP does.
    warn "This prints a personal recovery key ONCE. Save it before continuing."
    info "Encryption then runs in the background; the Mac stays usable."

    sudo -v
    sudo fdesetup enable -user "$USER" || {
        warn "FileVault was not enabled"
        return 1
    }

    success "FileVault enabled"
}

homebrew_analytics_disabled() {
    brew analytics state 2>/dev/null | grep -qi "disabled"
}

disable_homebrew_analytics() {
    # The shell exports HOMEBREW_NO_ANALYTICS; this covers every other context.
    info "Opting out of Homebrew analytics..."
    brew analytics off
    success "Homebrew analytics disabled"
}

report_protection_status() {
    info "Current protection status:"

    if command -v fdesetup >/dev/null 2>&1; then
        printf '  FileVault: %s\n' "$(fdesetup status 2>/dev/null || printf 'unknown')"
    fi

    if command -v csrutil >/dev/null 2>&1; then
        printf '  %s\n' "$(csrutil status 2>/dev/null || printf 'SIP: unknown')"
    fi

    if command -v spctl >/dev/null 2>&1; then
        printf '  Gatekeeper: %s\n' "$(spctl --status 2>&1 || printf 'unknown')"
    fi

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
    else
        warn "socketfilterfw not found; skipping firewall"
    fi

    offer_if_missing "Enable FileVault now (prints a recovery key you must save)?" macos_filevault_enabled enable_filevault "FileVault already enabled"

    offer "Disable remote login (SSH server)?" disable_remote_login
    offer "Disable Screen Sharing and Remote Apple Events (breaks IT remote assistance)?" disable_remote_services
    offer "Apply privacy defaults (crash reports, ads, analytics, iCloud, Bonjour)?" apply_privacy_defaults

    offer_if_missing "Auto-install security responses and system data files?" macos_automatic_security_updates_enabled enable_security_updates "Automatic security responses already enabled"

    require_command brew "the Homebrew analytics opt-out" && offer_if_missing "Opt out of Homebrew analytics?" homebrew_analytics_disabled disable_homebrew_analytics "Homebrew analytics already disabled"

    success "macOS hardening complete"
}

main "$@"
