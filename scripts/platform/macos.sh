#!/usr/bin/env bash
#
# Optional macOS setup for this dotfiles repo.
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASSETS_DIR="$REPO_ROOT/assets/macos"

XCODE_APP="${XCODE_APP:-/Applications/Xcode.app}"

# Dock contents, in order, applied by configure_dock. Missing apps are skipped.
DOCK_APPS=(
    "/System/Applications/Apps.app"
    "/Applications/Safari.app"
    "/Applications/Helium.app"
    "/Applications/Microsoft Edge.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"
    "/Applications/WhatsApp.app"
    "/Applications/Microsoft Teams.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/Discord.app"
    "/System/Applications/Music.app"
    "/Applications/Ghostty.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/Xcode.app"
)

# High-churn build output that Spotlight gains nothing from indexing. These are
# created if missing so a fresh machine is covered before the tools that fill
# them ever run.
SPOTLIGHT_EXCLUDED_PATHS=(
    "$HOME/Library/Developer/Xcode/DerivedData"
    "${XDG_CACHE_HOME:-$HOME/.cache}"
)

# Same idea, but owned by tools that create them on first use. Marked only when
# already present, so this script never pre-creates another program's directory.
SPOTLIGHT_OPTIONAL_PATHS=(
    "$HOME/Library/Developer/CoreSimulator"
    "${XDG_DATA_HOME:-$HOME/.local/share}/gradle"
    "${ANDROID_HOME:-$HOME/Library/Android/sdk}"
)

source "$REPO_ROOT/scripts/lib/setup.sh"
source "$REPO_ROOT/scripts/lib/javascript.sh"
source "$REPO_ROOT/scripts/lib/macos-state.sh"
# Provides ensure_xcode_cli_tools, shared with the bootstrap preflight.
source "$REPO_ROOT/scripts/lib/macos-preflight.sh"

rosetta_installed() {
    pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1
}

install_rosetta() {
    info "Installing Rosetta..."
    if softwareupdate --install-rosetta --agree-to-license; then
        success "Rosetta installed"
    else
        warn "Rosetta installation did not complete"
        return 1
    fi
}

apply_macos_defaults() {
    info "Applying macOS defaults..."

    # Finder
    defaults write com.apple.finder AppleShowAllFiles -bool false
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    # Search the folder you are standing in, not the whole Mac.
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    # New windows open in the home folder ("PfHm") rather than Recents.
    defaults write com.apple.finder NewWindowTarget -string "PfHm"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

    # Keyboard
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Panels
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    # Hold Control-Command and drag a window from anywhere in its body.
    defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true

    # Trackpad. The two domains are separate devices: AppleMultitouchTrackpad is
    # the built-in one, AppleBluetoothMultitouch.trackpad an external Magic
    # Trackpad. Setting only the Bluetooth domain leaves a laptop untouched.
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write com.apple.dock showAppExposeGestureEnabled -bool true

    # Dock
    defaults write com.apple.dock tilesize -int 32
    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock show-process-indicators -bool true
    defaults write com.apple.dock autohide -bool false
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock size-immutable -bool true

    # Mission Control
    defaults write com.apple.dock mru-spaces -bool false
    defaults write com.apple.dock expose-group-apps -bool true
    defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool true
    # false = "Displays have separate Spaces" stays on. The key is named for the
    # opposite behaviour, and unlike the rest of this block it only takes effect
    # after a log out; killall Dock is not enough.
    defaults write com.apple.spaces spans-displays -bool false

    # Hot corners: all disabled (0 = no action)
    local corner
    for corner in tl tr bl br; do
        defaults write com.apple.dock "wvous-${corner}-corner" -int 0
        defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
    done

    # Screenshots
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write com.apple.screencapture type -string "png"
    # Drop the wide translucent drop shadow around window captures.
    defaults write com.apple.screencapture disable-shadow -bool true

    # Enables the Web Inspector in the WebKit views other apps embed (Xcode
    # documentation, Mail). Safari itself is NOT configured here: it is
    # sandboxed, so `defaults write com.apple.Safari` lands in
    # ~/Library/Preferences and Safari reads its container plist instead. Those
    # writes look like they work and change nothing. Turn on the Develop menu in
    # Safari > Settings > Advanced.
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Xcode
    defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool true

    # Tips
    defaults write com.apple.tips TipsEnabled -bool false
    defaults write com.apple.tips CloudKitSyncingEnabled -bool false
    defaults write com.apple.tips NotificationsEnabled -bool false

    # Siri (Apple Intelligence features in Xcode remain available)
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    defaults write com.apple.Siri StatusMenuVisible -bool false
    defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false

    # Animation. NSWindowResizeTime is deliberately absent: it only ever applied
    # to the pre-Cocoa-Autolayout resize path and does nothing on current macOS.
    defaults write com.apple.universalaccess reduceMotion -bool false
    defaults write com.apple.dock launchanim -bool true
    defaults write com.apple.dock expose-animation-duration -float 0.1
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

    # Time Machine
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
    # Picks up the menu bar and Control Center side of the changes above.
    killall SystemUIServer 2>/dev/null || true

    success "macOS defaults applied"
    info "Separate Spaces per display takes effect after the next log out"
}

configure_power_management() {
    info "Configuring power management..."

    sudo -v
    sudo pmset -b sleep 60 displaysleep 15
    sudo pmset -c sleep 0 displaysleep 60
    sudo pmset -a powernap 0

    success "Power management configured"
}

library_folder_visible() {
    # BSD find matches file flags directly, so there is no ls output to parse.
    [[ -z "$(find "$HOME/Library" -maxdepth 0 -flags +hidden 2>/dev/null)" ]]
}

unhide_library_folder() {
    info "Unhiding $HOME/Library..."
    chflags nohidden "$HOME/Library"
    success "$HOME/Library is visible in Finder"
}

keyboard_layout_already_installed() {
    local target="$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    [[ -f "$target" ]] && cmp -s "$ASSETS_DIR/hungarian-win.keylayout" "$target"
}

install_keyboard_layout() {
    info "Installing Hungarian keyboard layout..."
    mkdir -p "$HOME/Library/Keyboard Layouts"
    cp "$ASSETS_DIR/hungarian-win.keylayout" "$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    success "Keyboard layout installed"
}

spotlight_exclusions_already_applied() {
    local path

    # Required paths are checked unconditionally. Skipping absent ones (as this
    # used to) reported "already applied" on a fresh machine, where none of them
    # exist yet, so the exclusions were never written at all.
    for path in "${SPOTLIGHT_EXCLUDED_PATHS[@]}"; do
        [[ -f "$path/.metadata_never_index" ]] || return 1
    done

    for path in "${SPOTLIGHT_OPTIONAL_PATHS[@]}"; do
        [[ -d "$path" ]] || continue
        [[ -f "$path/.metadata_never_index" ]] || return 1
    done

    return 0
}

configure_spotlight_exclusions() {
    info "Excluding high-churn dev paths from Spotlight..."

    # .metadata_never_index stops future indexing of a directory tree; anything
    # already in the index stays until the volume is reindexed. Marking the
    # paths before the build tools fill them is the point of creating them here.
    local path
    for path in "${SPOTLIGHT_EXCLUDED_PATHS[@]}"; do
        mkdir -p "$path"
        touch "$path/.metadata_never_index"
    done

    for path in "${SPOTLIGHT_OPTIONAL_PATHS[@]}"; do
        [[ -d "$path" ]] || continue
        touch "$path/.metadata_never_index"
    done

    success "Spotlight exclusions applied"
}

enable_touchid_sudo() {
    # macOS 14+ ships sudo_local.template and preserves sudo_local across system
    # updates, so this survives OS upgrades unlike editing /etc/pam.d/sudo.
    if [[ ! -f /etc/pam.d/sudo_local.template ]]; then
        warn "/etc/pam.d/sudo_local.template not found; needs macOS 14 or newer"
        return 1
    fi

    info "Enabling Touch ID for sudo..."
    sudo -v
    sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
    sudo chmod 444 /etc/pam.d/sudo_local

    if ! macos_touch_id_sudo_enabled; then
        error "Touch ID for sudo still reports disabled after the change"
        return 1
    fi

    success "Touch ID for sudo enabled"
}

computer_name_configured() {
    # There is no "correct" name to compare against, so only treat Apple's
    # generated default ("Gabor's MacBook Pro") as unconfigured and leave any
    # deliberate name alone. macOS uses a curly apostrophe in that default.
    local current=""
    current="$(scutil --get ComputerName 2>/dev/null)" || return 1
    [[ -n "$current" && "$current" != *"'s "* && "$current" != *"’s "* ]]
}

configure_computer_name() {
    local current="" new="" local_name=""

    if [[ ! -t 0 || ! -t 1 ]]; then
        info "Non-interactive shell; skipping computer name"
        return 0
    fi

    current="$(scutil --get ComputerName 2>/dev/null || printf '%s' "unknown")"
    printf '\nComputer name [%s]: ' "$current"
    IFS= read -r new

    if [[ -z "$new" ]]; then
        info "Keeping the current computer name"
        return 0
    fi

    # LocalHostName is a DNS label. Collapse unsupported characters into one
    # hyphen and strip hyphens from both ends.
    local_name="$(printf '%s' "$new" | sed -E 's/[^a-zA-Z0-9]+/-/g; s/^-+//; s/-+$//')"
    if [[ -z "$local_name" ]]; then
        warn "Computer name must contain at least one ASCII letter or number"
        return 1
    fi

    sudo -v
    sudo scutil --set ComputerName "$new"
    sudo scutil --set HostName "$local_name"
    sudo scutil --set LocalHostName "$local_name"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server \
        NetBIOSName -string "$local_name"

    success "Computer name set to $new ($local_name)"
}

configure_dock() {
    if ! command -v dockutil >/dev/null 2>&1; then
        warn "dockutil not installed; skipping Dock layout"
        info "Install it with: brew install dockutil"
        return 1
    fi

    info "Applying Dock layout..."

    local app
    dockutil --no-restart --remove all >/dev/null

    for app in "${DOCK_APPS[@]}"; do
        if [[ ! -d "$app" ]]; then
            warn "Not installed, skipping in Dock: $app"
            continue
        fi
        dockutil --no-restart --add "$app" >/dev/null
    done

    # Re-add the Downloads folder, wiped out by --remove all above.
    dockutil --no-restart --add "$HOME/Downloads" --view auto --display folder --section others >/dev/null

    killall Dock 2>/dev/null || true
    success "Dock layout applied"
}

xcode_ready() {
    [[ -d "$XCODE_APP" ]] || return 1
    [[ "$(xcode-select -p 2>/dev/null)" == "$XCODE_APP"/* ]] || return 1
    xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1
}

configure_xcode_first_launch() {
    if [[ ! -d "$XCODE_APP" ]]; then
        warn "$XCODE_APP not found; install the desired Xcode build first"
        return 1
    fi

    info "Running Xcode first-launch setup..."
    sudo -v
    sudo xcode-select -s "$XCODE_APP/Contents/Developer"
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch

    success "Xcode first-launch setup complete"
}

# mas 7 removed the `account` subcommand, so a signed-in App Store account
# cannot be probed directly. Report which declared apps are actually missing
# instead, which is the symptom that matters.
report_missing_app_store_apps() {
    local installed="" id="" name="" missing=()

    command -v mas >/dev/null 2>&1 || return 0
    [[ -f "$REPO_ROOT/Brewfile" ]] || return 0

    installed="$(mas list 2>/dev/null | awk '{print $1}')" || return 0

    while read -r id name; do
        grep -qx "$id" <<<"$installed" && continue
        # An app can be present without an App Store receipt (Xcode installed
        # via xcinfo or a direct download), which mas does not list.
        [[ -d "/Applications/$name.app" ]] && continue
        missing+=("$name ($id)")
    done < <(sed -n 's/^mas "\([^"]*\)", id: \([0-9]*\).*/\2 \1/p' "$REPO_ROOT/Brewfile")

    if ((${#missing[@]} == 0)); then
        info "All Mac App Store apps installed"
        return 0
    fi

    warn "Mac App Store apps not installed: ${missing[*]}"
    info "Sign in to the App Store, then: brew bundle install --file $REPO_ROOT/Brewfile"
}

gh_authenticated() {
    gh auth status >/dev/null 2>&1
}

setup_gh_auth() {
    if ! command -v gh >/dev/null 2>&1; then
        warn "gh not installed; skipping GitHub authentication"
        return 1
    fi

    info "Authenticating with GitHub..."
    gh auth login

    # Routes git's HTTPS credentials through gh, so clones and pushes work
    # without a separate credential setup.
    gh auth setup-git

    success "GitHub authentication configured"
}

llvm_dlltool_symlinked() {
    local llvm_prefix="" target=""
    llvm_prefix="$(brew --prefix llvm 2>/dev/null)" || return 1
    target="$HOME/.local/bin/dlltool"
    [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$llvm_prefix/bin/dlltool" ]]
}

setup_llvm_dlltool_symlink() {
    local llvm_prefix="" target=""
    llvm_prefix="$(brew --prefix llvm 2>/dev/null)" || {
        warn "LLVM not installed via Homebrew; skipping dlltool symlink"
        return 1
    }
    target="$HOME/.local/bin/dlltool"
    mkdir -p "$(dirname "$target")"
    ln -sf "$llvm_prefix/bin/dlltool" "$target"
    success "Symlinked ~/.local/bin/dlltool -> $llvm_prefix/bin/dlltool"
}

main() {
    require_platform macos

    info "macOS setup"

    ensure_xcode_cli_tools

    # First, so every later sudo prompt in this run (and in the two scripts at
    # the end) is a fingerprint instead of a typed password.
    prompt_if_missing \
        macos_touch_id_sudo_enabled \
        enable_touchid_sudo \
        "Enable Touch ID for sudo?" \
        "Touch ID for sudo already enabled"

    if [[ "$(uname -m)" == "arm64" ]]; then
        prompt_if_missing \
            rosetta_installed \
            install_rosetta \
            "Install Rosetta?" \
            "Rosetta already installed"
    else
        info "Not Apple Silicon; skipping Rosetta"
    fi

    prompt_if_missing \
        computer_name_configured \
        configure_computer_name \
        "Set the computer name?" \
        "Computer name already set"

    confirm_and_run "Apply macOS defaults?" apply_macos_defaults
    confirm_and_run "Configure power management?" configure_power_management
    confirm_and_run "Apply the Dock layout?" configure_dock
    prompt_if_missing \
        library_folder_visible \
        unhide_library_folder \
        "Unhide the user Library folder in Finder?" \
        "User Library folder already visible"

    prompt_if_missing \
        spotlight_exclusions_already_applied \
        configure_spotlight_exclusions \
        "Exclude high-churn dev paths from Spotlight?" \
        "Spotlight exclusions already applied"
    prompt_if_missing \
        keyboard_layout_already_installed \
        install_keyboard_layout \
        "Install the custom Hungarian keyboard layout?" \
        "Custom Hungarian keyboard layout already installed"

    prompt_if_missing \
        llvm_dlltool_symlinked \
        setup_llvm_dlltool_symlink \
        "Symlink LLVM dlltool into ~/.local/bin for Wine builds?" \
        "LLVM dlltool symlink already in place"

    report_missing_app_store_apps

    if [[ ! -d "$XCODE_APP" ]]; then
        info "Xcode not installed; skipping first-launch setup"
    else
        prompt_if_missing \
            xcode_ready \
            configure_xcode_first_launch \
            "Run Xcode first-launch setup (license, components, xcode-select)?" \
            "No pending Xcode first-launch setup"
    fi

    if ! command -v gh >/dev/null 2>&1; then
        info "gh not installed; skipping GitHub authentication"
    else
        prompt_if_missing \
            gh_authenticated \
            setup_gh_auth \
            "Authenticate the GitHub CLI?" \
            "GitHub CLI already authenticated"
    fi

    offer_javascript_toolchain_setup

    # Both scripts self-gate with their own confirm prompt.
    "$REPO_ROOT/scripts/platform/macos-hardening.sh"
    "$REPO_ROOT/scripts/platform/macos-office-tweaks.sh"

    success "macOS setup complete"
}

main "$@"
