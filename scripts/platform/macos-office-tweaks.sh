#!/usr/bin/env bash
#
# Permanently disable Microsoft auto-updaters on macOS so updates flow
# through topgrade only.
#
# Targets:
#   - Microsoft EdgeUpdater  (LaunchAgents + bundle + UpdateDefault policy)
#   - Microsoft AutoUpdate   (MAU; Teams / Office / OneNote / etc.)
#
# Strategy:
#   1. Bootout + delete existing LaunchAgents and updater bundles.
#   2. Apply user-domain disable preferences.
#   3. Replace each LaunchAgent path with a zero-byte sentinel locked with
#      the user/system immutable flag (uchg/schg) so the updater cannot
#      recreate the file on next launch.
#   4. Optionally install a managed configuration profile that pins
#      UpdateDefault=0 and HowToCheck=Manual at the system level.
#
# Idempotent: safe to re-run after Edge or an Office app reinstalls anything.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASSETS_DIR="$REPO_ROOT/assets/macos"
PROFILE_PATH="$ASSETS_DIR/disable-microsoft-updates.mobileconfig"

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

source "$REPO_ROOT/scripts/lib/common.sh"

require_macos() {
    [[ "$OSTYPE" == darwin* ]] || {
        error "This script is for macOS only"
        exit 1
    }
}

run_if_needed() {
    local label="$1" check_fn="$2" action_fn="$3"

    if "$check_fn"; then
        info "$label already applied"
        return 0
    fi

    confirm "$label?" && "$action_fn"
}

bootout_plist() {
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

# Replace path with a zero-byte sentinel and lock with the immutable flag.
# Prevents the updater from recreating its LaunchAgent on next launch.
seal_user_path() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    chflags nouchg "$path" 2>/dev/null || true
    : > "$path"
    chflags uchg "$path"
}

seal_system_path() {
    local path="$1"
    sudo mkdir -p "$(dirname "$path")"
    sudo chflags noschg "$path" 2>/dev/null || true
    sudo sh -c ": > '$path'"
    sudo chflags schg "$path"
}

is_sealed_path() {
    local path="$1" flags=""

    [[ -e "$path" ]] || return 1

    flags="$(ls -ldO "$path" 2>/dev/null)" || return 1
    [[ "$flags" == *"uchg"* || "$flags" == *"schg"* ]]
}

edge_updater_removed() {
    is_sealed_path "$HOME/Library/LaunchAgents/com.microsoft.EdgeUpdater.wake.plist" \
        && is_sealed_path "$HOME/Library/LaunchAgents/com.microsoft.EdgeUpdater.wake-system.plist" \
        && is_sealed_path "$HOME/Library/LaunchAgents/com.microsoft.EdgeUpdater.update.plist" \
        && is_sealed_path "$HOME/Library/LaunchAgents/com.microsoft.EdgeUpdater.update-system.plist"
}

edge_prefs_applied() {
    defaults read com.microsoft.EdgeUpdater updateDefault >/dev/null 2>&1 \
        && defaults read com.microsoft.EdgeUpdater installDefault >/dev/null 2>&1 \
        && defaults read com.microsoft.Edge UpdateDefault >/dev/null 2>&1 \
        && defaults read com.microsoft.Edge InstallDefault >/dev/null 2>&1
}

mau_disabled() {
    defaults read com.microsoft.autoupdate2 HowToCheck >/dev/null 2>&1 \
        && defaults read com.microsoft.autoupdate2 StartDaemonOnAppLaunch >/dev/null 2>&1 \
        && defaults read com.microsoft.autoupdate2 EnableCheckForUpdatesButton >/dev/null 2>&1 \
        && defaults read com.microsoft.autoupdate2 DisableInsiderCheckbox >/dev/null 2>&1 \
        && defaults read com.microsoft.autoupdate2 ChannelName >/dev/null 2>&1
}

config_profile_installed() {
    [[ -f "$PROFILE_PATH" ]]
}

remove_edge_updater() {
    info "Removing Microsoft EdgeUpdater LaunchAgents and bundles..."

    local uid
    uid="$(id -u)"

    for name in "${EDGE_UPDATER_AGENTS[@]}"; do
        bootout_plist "gui/$uid" "$HOME/Library/LaunchAgents/$name"
        bootout_plist "system" "/Library/LaunchAgents/$name"
        bootout_plist "system" "/Library/LaunchDaemons/$name"
    done

    rm -rf "$HOME/Library/Application Support/Microsoft/EdgeUpdater"
    sudo rm -rf "/Library/Application Support/Microsoft/EdgeUpdater"

    success "EdgeUpdater removed"
}

seal_edge_updater() {
    info "Sealing EdgeUpdater LaunchAgent paths with immutable sentinels..."

    for name in "${EDGE_UPDATER_AGENTS[@]}"; do
        seal_user_path "$HOME/Library/LaunchAgents/$name"
        seal_system_path "/Library/LaunchAgents/$name"
        seal_system_path "/Library/LaunchDaemons/$name"
    done

    success "EdgeUpdater paths sealed (chflags uchg / schg)"
}

apply_edge_prefs() {
    info "Applying Edge no-auto-update user-domain preferences..."

    defaults write com.microsoft.EdgeUpdater updateDefault -int 0
    defaults write com.microsoft.EdgeUpdater installDefault -int 0
    defaults write com.microsoft.Edge UpdateDefault -int 0
    defaults write com.microsoft.Edge InstallDefault -int 0

    success "Edge preferences applied"
}

disable_microsoft_autoupdate() {
    info "Disabling Microsoft AutoUpdate (MAU) and sealing its agents..."

    defaults write com.microsoft.autoupdate2 HowToCheck -string Manual
    defaults write com.microsoft.autoupdate2 StartDaemonOnAppLaunch -bool false
    defaults write com.microsoft.autoupdate2 EnableCheckForUpdatesButton -bool false
    defaults write com.microsoft.autoupdate2 DisableInsiderCheckbox -bool true
    defaults write com.microsoft.autoupdate2 ChannelName -string Current

    local uid
    uid="$(id -u)"

    for name in "${MAU_AGENTS[@]}"; do
        bootout_plist "gui/$uid" "$HOME/Library/LaunchAgents/$name"
        bootout_plist "system" "/Library/LaunchAgents/$name"
        bootout_plist "system" "/Library/LaunchDaemons/$name"
    done

    for name in "${MAU_AGENTS[@]}"; do
        seal_user_path "$HOME/Library/LaunchAgents/$name"
        seal_system_path "/Library/LaunchAgents/$name"
        seal_system_path "/Library/LaunchDaemons/$name"
    done

    success "MAU disabled and sealed"
}

install_config_profile() {
    if [[ ! -f "$PROFILE_PATH" ]]; then
        warn "Profile not found at $PROFILE_PATH; skipping"
        return 0
    fi

    info "Opening managed configuration profile in System Settings..."
    info "Approve it under: System Settings > Privacy & Security > Profiles"
    open "$PROFILE_PATH"

    success "Profile handed off to System Settings"
}

main() {
    require_macos

    info "Microsoft updater tweaks (Edge / Office / Teams)"
    warn "Sealing paths with chflags will block Microsoft auto-updates AND any reinstall attempt for those LaunchAgents."
    warn "To undo later: sudo chflags noschg <path>; chflags nouchg <path>; rm <path>"

    run_if_needed "Remove Microsoft EdgeUpdater" edge_updater_removed remove_edge_updater
    run_if_needed "Apply Edge user-domain preferences" edge_prefs_applied apply_edge_prefs
    run_if_needed "Seal EdgeUpdater paths with immutable flag" edge_updater_removed seal_edge_updater
    run_if_needed "Disable Microsoft AutoUpdate (MAU) and seal its paths" mau_disabled disable_microsoft_autoupdate
    run_if_needed "Install managed configuration profile (System Settings will open)" config_profile_installed install_config_profile

    success "Done!"
}

main "$@"
