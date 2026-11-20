#!/usr/bin/env bash
# Keep high-churn dev paths out of Spotlight with the Search Privacy list.
# macos.sh runs this, and it can also run alone.

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"

# Backs System Settings > Spotlight > Search Privacy. Root-only.
MACOS_SPOTLIGHT_CONFIG="/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist"
readonly MACOS_SPOTLIGHT_CONFIG

# Print the Spotlight Privacy list, one path per line. Needs root.
spotlight_privacy_list() {
    local count="" i

    # The key is absent until something has been excluded once.
    count="$(sudo plutil -extract Exclusions raw -o - "$MACOS_SPOTLIGHT_CONFIG" 2>/dev/null)" || return 0
    [[ "$count" =~ ^[0-9]+$ ]] || return 0
    for ((i = 0; i < count; i++)); do
        sudo plutil -extract "Exclusions.$i" raw -o - "$MACOS_SPOTLIGHT_CONFIG"
    done
}

# Print the existing exclusion paths that the Privacy list lacks. Needs root.
spotlight_missing_exclusions() {
    local current="" path

    current="$(spotlight_privacy_list)"
    while IFS= read -r path; do
        [[ -d "$path" ]] || continue
        grep -Fxq -- "$path" <<<"$current" || printf '%s\n' "$path"
    done < <(macos_spotlight_exclusion_paths)
}

# Uses cached sudo credentials only, so the check itself never prompts.
spotlight_exclusions_applied() {
    sudo -n true 2>/dev/null || return 1
    sudo -n plutil -p "$MACOS_SPOTLIGHT_CONFIG" >/dev/null 2>&1 || return 1
    [[ -z "$(spotlight_missing_exclusions)" ]]
}

# macOS 27 ignores .metadata_never_index markers. A folder name ending in
# .noindex still works, but these folders can't be renamed, so use the Privacy
# list. It lives in a root-only plist that mds reads when it starts.
configure_spotlight_exclusions() {
    local missing="" path="" still_missing=""

    info "Adding high-churn dev paths to the Spotlight Privacy list..."
    sudo -v
    mkdir -p -- "$XDG_CACHE_HOME"

    if ! sudo plutil -p "$MACOS_SPOTLIGHT_CONFIG" >/dev/null 2>&1; then
        warn "Cannot read $MACOS_SPOTLIGHT_CONFIG"
        info "Grant your terminal Full Disk Access and retry, or add the paths in System Settings > Spotlight > Search Privacy"
        return 1
    fi

    missing="$(spotlight_missing_exclusions)"
    if [[ -z "$missing" ]]; then
        success "Spotlight Privacy list already complete"
        return 0
    fi

    sudo plutil -extract Exclusions raw -o - "$MACOS_SPOTLIGHT_CONFIG" >/dev/null 2>&1 ||
        sudo plutil -insert Exclusions -array "$MACOS_SPOTLIGHT_CONFIG"

    while IFS= read -r path; do
        info "Excluding $path"
        sudo plutil -insert Exclusions -string "$path" -append "$MACOS_SPOTLIGHT_CONFIG"
    done <<<"$missing"

    # mds only reads the list at start. launchd respawns it at once.
    sudo launchctl kickstart -k system/com.apple.metadata.mds 2>/dev/null ||
        sudo killall mds 2>/dev/null || true

    # mds can rewrite the file from memory as it exits, so check that the
    # entries survived the restart.
    sleep 2
    still_missing="$(spotlight_missing_exclusions)"
    if [[ -n "$still_missing" ]]; then
        while IFS= read -r path; do
            error "Spotlight dropped this exclusion on restart: $path"
        done <<<"$still_missing"
        info "Add them in System Settings > Spotlight > Search Privacy"
        open "x-apple.systempreferences:com.apple.Spotlight-Settings.extension" 2>/dev/null || true
        return 1
    fi

    success "Spotlight Privacy list updated"

    # Already-indexed items stay searchable until the index is rebuilt. The
    # home folder lives on the Data volume, which has its own index, so erasing
    # / alone doesn't clear them.
    info "Rebuilding the Spotlight indexes so excluded items drop out..."
    sudo mdutil -E / >/dev/null || warn "Could not rebuild the Spotlight index for /"
    sudo mdutil -E /System/Volumes/Data >/dev/null ||
        warn "Could not rebuild the Spotlight index for /System/Volumes/Data"
    info "Spotlight re-indexes in the background, so searches may be incomplete for a while; make doctor reports anything that stays indexed"
}

main() {
    require_platform macos
    set_xdg_environment_defaults

    offer_if_missing "Add high-churn dev paths to the Spotlight Privacy list?" spotlight_exclusions_applied configure_spotlight_exclusions "Spotlight Privacy list already complete"
}

main "$@"
