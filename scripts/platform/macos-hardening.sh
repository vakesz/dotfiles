#!/usr/bin/env bash
#
# Optional macOS hardening, drawn from drduh/macOS-Security-and-Privacy-Guide.
#
# Scope is deliberately narrow: settings that raise the security floor without
# getting in the way of daily development work. Heavier measures remain manual.
#
# Idempotent: safe to re-run.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "$REPO_ROOT/scripts/lib/setup.sh"
# Provides MACOS_FIREWALL and the read-only state checks, shared with doctor.sh.
source "$REPO_ROOT/scripts/lib/macos-state.sh"

enable_firewall() {
    macos_firewall_available || {
        warn "socketfilterfw not found; skipping firewall"
        return 1
    }

    if macos_mdm_managed; then
        warn "This Mac is MDM-managed; socketfilterfw refuses command-line changes"
        info "The firewall is set by your management profile, not by this script"
        return 1
    fi

    info "Enabling the application firewall..."
    sudo -v

    sudo "$MACOS_FIREWALL" --setglobalstate on >/dev/null
    # Logs blocked connections to /var/log/appfirewall.log, which is the only
    # way to find out what the firewall actually stopped.
    sudo "$MACOS_FIREWALL" --setloggingmode on >/dev/null

    # Deliberately NOT setting --setallowsigned off: it makes macOS prompt for
    # approval on every signed binary that listens, which is unworkable for
    # development servers.
    #
    # Stealth mode is also left alone: it stops the machine answering ping,
    # which is worth more during local network debugging than it costs.

    sudo pkill -HUP socketfilterfw 2>/dev/null || true

    # socketfilterfw exits 0 even when it declined to do anything, so the write
    # is worth nothing without reading the state back.
    if ! macos_firewall_enabled; then
        error "Firewall still reports disabled after the change"
        return 1
    fi

    success "Firewall enabled"
}

disable_remote_login() {
    # `systemsetup -getremotelogin` needs sudo to read, so this is applied
    # unconditionally rather than gated on a check. Turning it off twice is a
    # no-op.
    info "Disabling remote login (SSH server)..."
    sudo -v

    # -f skips systemsetup's own "Do you really want to turn remote login off?"
    # confirmation. Without it the command waits on stdin, and with stdio
    # discarded that looks like a hang after the script's own y/N prompt.
    sudo systemsetup -f -setremotelogin off >/dev/null || {
        warn "Could not change remote login; grant Full Disk Access to your terminal"
        return 1
    }
    success "Remote login disabled"
}

disable_remote_services() {
    local failed=0

    # Screen Sharing / Apple Remote Desktop and Remote Apple Events are both
    # off by default; this makes that explicit and undoes a machine where a
    # guide or an old setup turned them on.
    info "Disabling Screen Sharing and Remote Apple Events..."
    sudo -v

    # -f skips systemsetup's own confirmation, the same reason the remote login
    # call above passes it.
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

    # Stop the crash reporter dialog from offering to send reports to Apple.
    # This also hides the dialog for apps built locally; the crash logs are
    # still written under ~/Library/Logs/DiagnosticReports.
    defaults write com.apple.CrashReporter DialogType -string none

    # New documents default to the local disk rather than iCloud Drive.
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    # Personalised ads, and the advertising identifier they are keyed on.
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false

    # Stop advertising services (and the hostname) over Bonjour multicast.
    sudo -v
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder \
        NoMulticastAdvertisements -bool true

    # Stop automatic submission of diagnostics to Apple and to third-party
    # developers. This is the "Share Mac Analytics" pair in System Settings.
    sudo defaults write \
        "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" \
        AutoSubmit -bool false
    sudo defaults write \
        "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" \
        ThirdPartyDataSubmit -bool false

    # Require the password immediately when the screen locks. macOS 13+ largely
    # manages this through Lock Screen settings and may ignore these keys, so
    # treat it as best effort and confirm in System Settings.
    defaults write com.apple.screensaver askForPassword -int 1 2>/dev/null || true
    defaults write com.apple.screensaver askForPasswordDelay -int 0 2>/dev/null || true

    success "Privacy defaults applied"
}

enable_security_updates() {
    # Deliberately narrow: only XProtect/Gatekeeper data and Rapid Security
    # Responses. Whether full macOS updates install automatically is left alone,
    # because topgrade drives those.
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
    if [[ ! -t 0 || ! -t 1 ]]; then
        info "Non-interactive shell; skipping FileVault"
        return 0
    fi

    # Contrary to a common claim, FileVault does not need Recovery: fdesetup
    # turns it on from a running system. SIP genuinely does need Recovery, which
    # is why only SIP is report-only here.
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
    command -v brew >/dev/null 2>&1 || {
        warn "brew not found; skipping analytics opt-out"
        return 1
    }

    # The shell already exports HOMEBREW_NO_ANALYTICS, but that only covers
    # interactive shells. This persists the opt-out for every other context.
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

    # SIP is the only one of the three that genuinely needs Recovery.
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

    if ! macos_firewall_available; then
        warn "socketfilterfw not found; skipping firewall"
    else
        prompt_if_missing \
            macos_firewall_enabled \
            enable_firewall \
            "Enable the application firewall?" \
            "Firewall already enabled"
    fi

    prompt_if_missing \
        macos_filevault_enabled \
        enable_filevault \
        "Enable FileVault now (prints a recovery key you must save)?" \
        "FileVault already enabled"

    confirm_and_run "Disable remote login (SSH server)?" disable_remote_login
    confirm_and_run \
        "Disable Screen Sharing and Remote Apple Events (breaks IT remote assistance)?" \
        disable_remote_services
    confirm_and_run "Apply privacy defaults (crash reports, ads, analytics, iCloud, Bonjour)?" apply_privacy_defaults

    prompt_if_missing \
        macos_automatic_security_updates_enabled \
        enable_security_updates \
        "Auto-install security responses and system data files?" \
        "Automatic security responses already enabled"

    if ! command -v brew >/dev/null 2>&1; then
        warn "brew not found; skipping analytics opt-out"
    else
        prompt_if_missing \
            homebrew_analytics_disabled \
            disable_homebrew_analytics \
            "Opt out of Homebrew analytics?" \
            "Homebrew analytics already disabled"
    fi

    success "macOS hardening complete"
}

main "$@"
