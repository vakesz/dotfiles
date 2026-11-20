#!/usr/bin/env bash
# macOS data lists, state checks and small helpers shared by the setup and
# doctor scripts. macos-preflight.sh sources this before Homebrew exists and
# CI runs doctor under /bin/bash, so keep it bash 3.2 compatible.

# Guard against double-sourcing: macos.sh sources both this file and
# macos-preflight.sh (which sources this file again). Reassigning a readonly
# would abort under `set -e`.
[[ -n "${__DOTFILES_MACOS_STATE_LOADED:-}" ]] && return 0
__DOTFILES_MACOS_STATE_LOADED=1

MACOS_FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"
readonly MACOS_FIREWALL
XCODE_APP="${XCODE_APP:-/Applications/Xcode.app}"
readonly XCODE_APP

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
    "$XCODE_APP"
    "/Applications/Ghostty.app"
    "/Applications/T3 Code (Nightly).app"
)
# shellcheck disable=SC2034 # read by macos.sh
readonly DOCK_APPS

# The generated LaunchAgent that gives GUI apps the ~/.zshenv variables.
LAUNCHD_ENV_LABEL="io.github.vakesz.dotfiles.launchd-env"
readonly LAUNCHD_ENV_LABEL
LAUNCHD_ENV_PLIST="$HOME/Library/LaunchAgents/$LAUNCHD_ENV_LABEL.plist"
readonly LAUNCHD_ENV_PLIST

# FUSE-T and Omnimount, shared by macos-omnimount.sh and doctor.sh.
FUSE_T_CASK="fuse-t"
FUSE_T_LIB="/usr/local/lib/libfuse-t.dylib"
MACFUSE_FS="/Library/Filesystems/macfuse.fs"
OMNIMOUNT_APP="/Applications/Omnimount.app"
readonly FUSE_T_CASK FUSE_T_LIB MACFUSE_FS OMNIMOUNT_APP

# High-churn dev paths to keep out of Spotlight, one per line. Callers set the
# XDG variables first. Only paths that exist are excluded.
macos_spotlight_exclusion_paths() {
    printf '%s\n' \
        "$HOME/projects" \
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

# Every item Spotlight has indexed under $HOME, one path per line. Scoping
# mdfind to a sandbox container returns nothing, so callers filter this
# listing instead.
macos_spotlight_indexed_home() {
    mdfind -onlyin "$HOME" 'kMDItemContentTypeTree == "public.item"' 2>/dev/null
}

# True on Apple Silicon, including under Rosetta (unlike `uname -m`).
macos_apple_silicon() {
    [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]
}

# Set MACOS_BREW_PREFIX once. Call it in the current shell, never inside $(...),
# or the cache is lost to the subshell. Returns 1 while brew is unavailable.
MACOS_BREW_PREFIX=""
macos_brew_prefix() {
    if [[ -z "$MACOS_BREW_PREFIX" ]]; then
        MACOS_BREW_PREFIX="${HOMEBREW_PREFIX:-}"
    fi
    if [[ -z "$MACOS_BREW_PREFIX" ]]; then
        MACOS_BREW_PREFIX="$(brew --prefix 2>/dev/null)" || MACOS_BREW_PREFIX=""
    fi
    [[ -n "$MACOS_BREW_PREFIX" ]]
}

# The LaunchAgent plist macos.sh installs. It needs absolute paths, so it is
# generated rather than stowed. Needs DOTFILES_ROOT from paths.sh.
macos_launchd_env_plist() {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LAUNCHD_ENV_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>-f</string>
        <string>$DOTFILES_ROOT/scripts/platform/launchd-env.zsh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
}

# True when the generated LaunchAgent is on disk and launchd has it loaded.
macos_launchd_env_agent_loaded() {
    [[ -f "$LAUNCHD_ENV_PLIST" ]] &&
        launchctl print "gui/$(id -u)/$LAUNCHD_ENV_LABEL" >/dev/null 2>&1
}

# True when the installed plist is exactly what this checkout would generate.
# False after the script moved or the repo was cloned somewhere else.
macos_launchd_env_agent_current() {
    [[ -f "$LAUNCHD_ENV_PLIST" ]] &&
        [[ "$(cat "$LAUNCHD_ENV_PLIST")" == "$(macos_launchd_env_plist)" ]]
}

# Print the script the installed LaunchAgent runs.
macos_launchd_env_agent_script() {
    /usr/libexec/PlistBuddy -c 'Print :ProgramArguments:2' "$LAUNCHD_ENV_PLIST" 2>/dev/null
}

# True when the fuse-t cask is installed. Slow (runs brew), so call it once.
macos_fuse_t_cask_installed() {
    brew list --cask "$FUSE_T_CASK" >/dev/null 2>&1
}

# The cask can be listed while the privileged pkg copy of the library is missing.
macos_fuse_t_lib_present() {
    [[ -f "$FUSE_T_LIB" ]]
}

macos_macfuse_present() {
    [[ -e "$MACFUSE_FS" ]]
}

macos_omnimount_app_version() {
    local version=""

    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$OMNIMOUNT_APP/Contents/Info.plist" 2>/dev/null)" || return 1
    [[ -n "$version" ]] || return 1
    printf '%s\n' "$version"
}

# First line of `$1 --version`, without using a pipe (pipefail + head).
macos_omnimount_cli_version() {
    local version=""

    version="$("$1" --version 2>/dev/null)" || return 1
    version="${version%%$'\n'*}"
    version="${version//$'\r'/}"
    [[ -n "$version" ]] || return 1
    printf '%s\n' "$version"
}

# On a managed Mac, a profile can reject or later revert a setting that looked applied.
macos_mdm_managed() {
    profiles status -type enrollment 2>/dev/null | grep -qi 'MDM enrollment: Yes'
}

# True when a configuration profile sets key $2 in preference domain $1,
# machine-wide or for this user. These files are world-readable.
macos_managed_pref_set() {
    local dir=""

    for dir in "/Library/Managed Preferences" "/Library/Managed Preferences/$(id -un)"; do
        defaults read "$dir/$1" "$2" >/dev/null 2>&1 && return 0
    done
    return 1
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

# True when the firewall lets neither built-in nor downloaded signed software
# accept connections without asking.
macos_firewall_signed_allowlist_off() {
    local state=""

    macos_firewall_available || return 1
    state="$("$MACOS_FIREWALL" --getallowsigned 2>/dev/null)" || return 1
    [[ "$state" == *DISABLED* && "$state" != *ENABLED* ]]
}

macos_gatekeeper_enabled() {
    spctl --status 2>/dev/null | grep -q "assessments enabled"
}

macos_filevault_enabled() {
    fdesetup status 2>/dev/null | grep -q "FileVault is On"
}

# A custom configuration prints "enabled (Custom Configuration)" or
# "unknown (Custom Configuration)", so match the full, unqualified status.
macos_sip_enabled() {
    csrutil status 2>/dev/null | grep -q 'status: enabled\.'
}

# ConfigDataInstall (XProtect data) and CriticalUpdateInstall (security
# responses) only take effect when macOS also checks for and downloads updates.
macos_automatic_security_updates_enabled() {
    local domain="/Library/Preferences/com.apple.SoftwareUpdate" key=""

    for key in AutomaticCheckEnabled AutomaticDownload ConfigDataInstall CriticalUpdateInstall; do
        [[ "$(defaults read "$domain" "$key" 2>/dev/null)" == "1" ]] || return 1
    done
}

# ARDAgent runs only while Remote Management is on.
macos_remote_management_active() {
    pgrep -qx ARDAgent
}

macos_auto_login_enabled() {
    defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser >/dev/null 2>&1 ||
        [[ -e /etc/kcpassword ]]
}

# smbd is disabled in its launchd plist; turning File Sharing on adds an
# override that `print-disabled` lists as enabled (false on older macOS).
macos_file_sharing_enabled() {
    launchctl print-disabled system 2>/dev/null | grep -qE '"com\.apple\.smbd" => (enabled|false)'
}

macos_printer_sharing_enabled() {
    cupsctl 2>/dev/null | grep -qx '_share_printers=1'
}

macos_internet_sharing_enabled() {
    local value=""

    value="$(/usr/libexec/PlistBuddy -c 'Print :NAT:Enabled' /Library/Preferences/SystemConfiguration/com.apple.nat.plist 2>/dev/null)" || return 1
    [[ "$value" == "1" || "$value" == "true" ]]
}

macos_media_sharing_enabled() {
    [[ "$(defaults read com.apple.amp.mediasharingd home-sharing-enabled 2>/dev/null)" == "1" ]]
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
