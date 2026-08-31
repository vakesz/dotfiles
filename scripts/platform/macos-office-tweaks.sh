#!/usr/bin/env bash
#
# Repeatably disable Microsoft auto-updaters on macOS so updates flow through
# topgrade only. Rerun after an application update restores updater artifacts.
#
# Targets:
#   - Microsoft EdgeUpdater  (LaunchAgents + bundle + UpdateDefault policy)
#   - Microsoft AutoUpdate   (MAU; Teams / Office / OneNote / etc.)
#
# Strategy:
#   1. Apply user-domain disable preferences first, so even an interrupted run
#      leaves updaters disabled.
#   2. Bootout + delete existing LaunchAgents and the EdgeUpdater bundle.
#
# Idempotent: safe to re-run after Edge or an Office app reinstalls anything.
# No immutable flags or file ownership changes are applied.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

EDGE_UPDATER_AGENTS=(
    com.microsoft.EdgeUpdater.wake.plist
    com.microsoft.EdgeUpdater.wake-system.plist
    com.microsoft.EdgeUpdater.update.plist
    com.microsoft.EdgeUpdater.update-system.plist
)

MAU_AGENTS=(
    com.microsoft.update.agent.plist
    com.microsoft.autoupdate.helper.plist
    com.microsoft.autoupdate.helpertool.plist
)

source "$REPO_ROOT/scripts/lib/setup.sh"

remove_launchd_plist() {
    local domain="$1" plist="$2"
    [[ -e "$plist" ]] || return 0

    if [[ "$domain" == "system" ]]; then
        sudo launchctl bootout system "$plist" 2>/dev/null || true
        sudo chflags noschg "$plist" 2>/dev/null || true
        sudo rm -f "$plist"
    else
        launchctl bootout "$domain" "$plist" 2>/dev/null || true
        chflags nouchg "$plist" 2>/dev/null || true
        rm -f "$plist"
    fi
}

apply_edge_prefs() {
    info "Applying Edge no-auto-update user-domain preferences..."

    defaults write com.microsoft.EdgeUpdater updateDefault -int 0
    defaults write com.microsoft.EdgeUpdater installDefault -int 0
    defaults write com.microsoft.Edge UpdateDefault -int 0
    defaults write com.microsoft.Edge InstallDefault -int 0

    success "Edge preferences applied"
}

apply_mau_prefs() {
    info "Applying MAU no-auto-update user-domain preferences..."

    defaults write com.microsoft.autoupdate2 HowToCheck -string Manual
    defaults write com.microsoft.autoupdate2 StartDaemonOnAppLaunch -bool false
    defaults write com.microsoft.autoupdate2 EnableCheckForUpdatesButton -bool false
    defaults write com.microsoft.autoupdate2 DisableInsiderCheckbox -bool true
    defaults write com.microsoft.autoupdate2 ChannelName -string Current

    success "MAU preferences applied"
}

remove_edge_updater() {
    info "Removing Microsoft EdgeUpdater LaunchAgents and bundles..."

    local uid
    uid="$(id -u)"

    for name in "${EDGE_UPDATER_AGENTS[@]}"; do
        remove_launchd_plist "gui/$uid" "$HOME/Library/LaunchAgents/$name"
        remove_launchd_plist "system" "/Library/LaunchAgents/$name"
        remove_launchd_plist "system" "/Library/LaunchDaemons/$name"
    done

    rm -rf "$HOME/Library/Application Support/Microsoft/EdgeUpdater"
    sudo rm -rf "/Library/Application Support/Microsoft/EdgeUpdater"

    success "EdgeUpdater removed"
}

remove_microsoft_autoupdate() {
    info "Removing Microsoft AutoUpdate (MAU) LaunchAgents..."

    local uid
    uid="$(id -u)"

    for name in "${MAU_AGENTS[@]}"; do
        remove_launchd_plist "gui/$uid" "$HOME/Library/LaunchAgents/$name"
        remove_launchd_plist "system" "/Library/LaunchAgents/$name"
        remove_launchd_plist "system" "/Library/LaunchDaemons/$name"
    done

    success "MAU LaunchAgents removed"
}

main() {
    require_platform macos

    info "Microsoft updater tweaks (Edge / Office / Teams)"

    confirm "Apply Microsoft updater tweaks now?" || {
        info "Skipping Microsoft updater tweaks"
        return 0
    }

    apply_edge_prefs
    apply_mau_prefs
    remove_edge_updater
    remove_microsoft_autoupdate

    success "Microsoft updater tweaks complete"
}

main "$@"
