#!/usr/bin/env bash
#
# Optional macOS hardening, drawn from drduh/macOS-Security-and-Privacy-Guide.
#
# Scope is deliberately narrow: settings that raise the security floor without
# getting in the way of daily development work. The guide's heavier measures are
# intentionally excluded, and the reasons are recorded in README.md so this file
# does not quietly grow them back.
#
# Idempotent: safe to re-run.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"

source "$REPO_ROOT/scripts/lib/common.sh"

firewall_enabled() {
    "$FIREWALL" --getglobalstate 2>/dev/null | grep -q "enabled"
}

enable_firewall() {
    [[ -x "$FIREWALL" ]] || {
        warn "socketfilterfw not found; skipping firewall"
        return 1
    }

    info "Enabling the application firewall..."
    sudo -v

    sudo "$FIREWALL" --setglobalstate on >/dev/null

    # Deliberately NOT setting --setallowsigned off: it makes macOS prompt for
    # approval on every signed binary that listens, which is unworkable for
    # development servers.
    #
    # Stealth mode is also left alone: it stops the machine answering ping,
    # which is worth more during local network debugging than it costs.

    sudo pkill -HUP socketfilterfw 2>/dev/null || true

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

apply_privacy_defaults() {
    info "Applying privacy defaults..."

    # Stop the crash reporter dialog from offering to send reports to Apple.
    defaults write com.apple.CrashReporter DialogType -string none

    # New documents default to the local disk rather than iCloud Drive.
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    # Stop advertising services (and the hostname) over Bonjour multicast.
    sudo -v
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder \
        NoMulticastAdvertisements -bool true

    # Require the password immediately when the screen locks. macOS 13+ largely
    # manages this through Lock Screen settings and may ignore these keys, so
    # treat it as best effort and confirm in System Settings.
    defaults write com.apple.screensaver askForPassword -int 1 2>/dev/null || true
    defaults write com.apple.screensaver askForPasswordDelay -int 0 2>/dev/null || true

    success "Privacy defaults applied"
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

library_folder_visible() {
    # BSD find matches on file flags directly, which avoids parsing ls output.
    [[ -z "$(find "$HOME/Library" -maxdepth 0 -flags +hidden 2>/dev/null)" ]]
}

unhide_library_folder() {
    info "Unhiding $HOME/Library..."
    chflags nohidden "$HOME/Library"
    success "$HOME/Library is visible in Finder"
}

report_disk_encryption_status() {
    info "Current protection status:"

    if command -v fdesetup >/dev/null 2>&1; then
        printf '  FileVault: %s\n' "$(fdesetup status 2>/dev/null || printf 'unknown')"
    fi

    if command -v csrutil >/dev/null 2>&1; then
        printf '  %s\n' "$(csrutil status 2>/dev/null || printf 'SIP: unknown')"
    fi

    # Both require a reboot into recovery to change, so this only reports.
    info "FileVault and SIP are changed from Recovery, not from this script"
}

main() {
    require_platform macos

    info "macOS hardening (optional)"

    confirm "Apply optional macOS hardening now?" || {
        info "Skipping macOS hardening"
        return 0
    }

    report_disk_encryption_status

    if [[ ! -x "$FIREWALL" ]]; then
        warn "socketfilterfw not found; skipping firewall"
    else
        prompt_if_missing \
            firewall_enabled \
            enable_firewall \
            "Enable the application firewall?" \
            "Firewall already enabled"
    fi

    confirm_and_run "Disable remote login (SSH server)?" disable_remote_login
    confirm_and_run "Apply privacy defaults (crash reports, iCloud, Bonjour)?" apply_privacy_defaults

    if ! command -v brew >/dev/null 2>&1; then
        warn "brew not found; skipping analytics opt-out"
    else
        prompt_if_missing \
            homebrew_analytics_disabled \
            disable_homebrew_analytics \
            "Opt out of Homebrew analytics?" \
            "Homebrew analytics already disabled"
    fi

    prompt_if_missing \
        library_folder_visible \
        unhide_library_folder \
        "Unhide the user Library folder in Finder?" \
        "User Library folder already visible"

    success "macOS hardening complete"
}

main "$@"
