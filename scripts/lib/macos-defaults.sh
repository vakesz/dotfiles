#!/usr/bin/env bash
# The macOS defaults macos.sh applies and doctor.sh checks, as one table, with
# the helpers that read, compare and write it. CI runs doctor under /bin/bash,
# so keep this bash 3.2 compatible.

[[ -n "${__DOTFILES_MACOS_DEFAULTS_LOADED:-}" ]] && return 0
__DOTFILES_MACOS_DEFAULTS_LOADED=1

# Print the table, one row per line: scope|domain|key|type|value
#   scope: user (`defaults`) or host (`defaults -currentHost`)
#   type:  bool, int, float or string, as passed to `defaults write -<type>`
# Values can't contain "|". Nothing here needs root.
macos_defaults_rows() {
    local corner rows=(
        # Finder
        "user|com.apple.finder|AppleShowAllFiles|bool|false"
        "user|NSGlobalDomain|AppleShowAllExtensions|bool|true"
        "user|com.apple.finder|ShowStatusBar|bool|true"
        "user|com.apple.finder|ShowPathbar|bool|true"
        "user|com.apple.finder|FXPreferredViewStyle|string|Nlsv"
        "user|com.apple.finder|_FXSortFoldersFirst|bool|true"
        "user|com.apple.finder|FXArrangeGroupViewBy|string|Name"
        "user|com.apple.desktopservices|DSDontWriteNetworkStores|bool|true"
        "user|com.apple.desktopservices|DSDontWriteUSBStores|bool|true"
        "user|com.apple.finder|FXEnableExtensionChangeWarning|bool|false"
        # SCcf: search the current folder. PfHm: new windows open at $HOME.
        "user|com.apple.finder|FXDefaultSearchScope|string|SCcf"
        "user|com.apple.finder|NewWindowTarget|string|PfHm"
        "user|com.apple.finder|NewWindowTargetPath|string|file://$HOME/"

        # Keyboard. 2 is what System Settings > Keyboard > Keyboard navigation
        # writes on macOS 13 and later; the older 3 shows up there as drift.
        "user|NSGlobalDomain|AppleKeyboardUIMode|int|2"
        "user|NSGlobalDomain|KeyRepeat|int|2"
        "user|NSGlobalDomain|InitialKeyRepeat|int|15"
        "user|NSGlobalDomain|NSAutomaticDashSubstitutionEnabled|bool|false"
        "user|NSGlobalDomain|NSAutomaticCapitalizationEnabled|bool|false"
        "user|NSGlobalDomain|NSAutomaticPeriodSubstitutionEnabled|bool|false"
        "user|NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|bool|false"
        "user|NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled|bool|false"

        # Panels
        "user|NSGlobalDomain|NSNavPanelExpandedStateForSaveMode|bool|true"
        "user|NSGlobalDomain|PMPrintingExpandedStateForPrint|bool|true"
        "user|NSGlobalDomain|NSWindowShouldDragOnGesture|bool|true"

        # Trackpad. The built-in trackpad and a Magic Trackpad use separate domains.
        "user|com.apple.AppleMultitouchTrackpad|Clicking|bool|true"
        "user|com.apple.driver.AppleBluetoothMultitouch.trackpad|Clicking|bool|true"
        "host|NSGlobalDomain|com.apple.mouse.tapBehavior|int|1"
        "user|NSGlobalDomain|com.apple.mouse.tapBehavior|int|1"
        "user|com.apple.dock|showAppExposeGestureEnabled|bool|true"

        # Dock
        "user|com.apple.dock|tilesize|int|32"
        "user|com.apple.dock|mineffect|string|scale"
        "user|com.apple.dock|minimize-to-application|bool|true"
        "user|com.apple.dock|show-process-indicators|bool|true"
        "user|com.apple.dock|autohide|bool|false"
        "user|com.apple.dock|show-recents|bool|false"
        "user|com.apple.dock|size-immutable|bool|true"

        # Mission Control
        "user|com.apple.dock|mru-spaces|bool|false"
        "user|com.apple.dock|expose-group-apps|bool|true"
        "user|NSGlobalDomain|AppleSpacesSwitchOnActivate|bool|true"
        # false turns "Displays have separate Spaces" on. Applies after logging out.
        "user|com.apple.spaces|spans-displays|bool|false"

        # Screenshots
        "user|com.apple.screencapture|location|string|$HOME/Desktop"
        "user|com.apple.screencapture|type|string|png"
        "user|com.apple.screencapture|disable-shadow|bool|true"

        # Sandboxed Safari ignores this; use Safari > Settings > Advanced instead.
        "user|NSGlobalDomain|WebKitDeveloperExtras|bool|true"

        # Xcode
        "user|com.apple.dt.Xcode|ShowBuildOperationDuration|bool|true"

        # Tips
        "user|com.apple.tips|TipsEnabled|bool|false"
        "user|com.apple.tips|CloudKitSyncingEnabled|bool|false"
        "user|com.apple.tips|NotificationsEnabled|bool|false"

        # Siri
        "user|com.apple.assistant.support|Assistant Enabled|bool|false"
        "user|com.apple.Siri|StatusMenuVisible|bool|false"
        "user|com.apple.Siri|VoiceTriggerUserEnabled|bool|false"

        # Animation
        "user|com.apple.dock|launchanim|bool|true"
        "user|com.apple.dock|expose-animation-duration|float|0.1"
        "user|NSGlobalDomain|NSAutomaticWindowAnimationsEnabled|bool|false"

        # Time Machine
        "user|com.apple.TimeMachine|DoNotOfferNewDisksForBackup|bool|true"
    )

    # Hot corners: 0 means no action.
    for corner in tl tr bl br; do
        rows+=(
            "user|com.apple.dock|wvous-$corner-corner|int|0"
            "user|com.apple.dock|wvous-$corner-modifier|int|0"
        )
    done

    printf '%s\n' "${rows[@]}"
}

# Print the current value of key $3 in domain $2 (scope $1); fail when unset.
macos_defaults_read() {
    if [[ "$1" == "host" ]]; then
        defaults -currentHost read "$2" "$3" 2>/dev/null
    else
        defaults read "$2" "$3" 2>/dev/null
    fi
}

# Write value $5 of type $4 to key $3 in domain $2 (scope $1).
macos_defaults_write() {
    if [[ "$1" == "host" ]]; then
        defaults -currentHost write "$2" "$3" "-$4" "$5"
    else
        defaults write "$2" "$3" "-$4" "$5"
    fi
}

# True when `defaults read` output $3 means the same as table value $2 of type
# $1. `defaults read` prints bools as 1/0 and floats in its own precision.
macos_defaults_equal() {
    local type="$1" want="$2" have="$3"

    case "$type" in
        bool)
            case "$want" in true) want=1 ;; false) want=0 ;; esac
            case "$have" in
                1 | true | TRUE | YES | yes) have=1 ;;
                0 | false | FALSE | NO | no) have=0 ;;
            esac
            [[ "$have" == "$want" ]]
            ;;
        int)
            [[ "$have" =~ ^-?[0-9]+$ ]] && ((have == want))
            ;;
        float)
            [[ "$have" =~ ^-?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$ ]] || return 1
            awk -v a="$have" -v b="$want" 'BEGIN { d = a - b; if (d < 0) d = -d; exit !(d < 1e-6) }'
            ;;
        *)
            [[ "$have" == "$want" ]]
            ;;
    esac
}

# Print every row whose current value differs, as the row plus "|current",
# where current is "<unset>" for a missing key.
macos_defaults_drift() {
    local scope domain key type value have

    while IFS='|' read -r scope domain key type value; do
        if ! have="$(macos_defaults_read "$scope" "$domain" "$key")"; then
            have="<unset>"
        elif macos_defaults_equal "$type" "$value" "$have"; then
            continue
        fi
        printf '%s|%s|%s|%s|%s|%s\n' "$scope" "$domain" "$key" "$type" "$value" "$have"
    done < <(macos_defaults_rows)
}

# True when every row already matches.
macos_defaults_applied() {
    [[ -z "$(macos_defaults_drift)" ]]
}
