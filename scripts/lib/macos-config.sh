#!/usr/bin/env bash
# macOS data lists: Spotlight exclusions and Dock layout. XCODE_APP comes from
# macos-state.sh, which sources this file; the default here keeps standalone sourcing safe.

[[ -n "${__DOTFILES_MACOS_CONFIG_LOADED:-}" ]] && return 0
__DOTFILES_MACOS_CONFIG_LOADED=1

DOCK_APPS=(
    "/System/Applications/Apps.app"
    "/Applications/Safari.app"
    "/Applications/Firefox.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"
    "/Applications/WhatsApp.app"
    "/Applications/Microsoft Teams.app"
    "/Applications/Microsoft Outlook.app"
    "/System/Applications/Music.app"
    "/Applications/Visual Studio Code.app"
    "${XCODE_APP:-/Applications/Xcode.app}"
    "/Applications/Ghostty.app"
    "/Applications/T3 Code (Nightly).app"
)
# shellcheck disable=SC2034 # read by macos.sh
readonly DOCK_APPS

# High-churn dev paths to keep out of Spotlight, one per line. Callers set the
# XDG variables first. Only paths that exist are excluded.
macos_spotlight_exclusion_paths() {
    printf '%s\n' \
        "$HOME/Code" \
        "$HOME/Work" \
        "$XDG_CACHE_HOME" \
        "$XDG_DATA_HOME/gradle" \
        "$XDG_DATA_HOME/pnpm" \
        "$XDG_DATA_HOME/android" \
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
