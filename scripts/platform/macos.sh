#!/usr/bin/env bash
# Optional macOS setup for this dotfiles repo.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/node.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-preflight.sh"

set_xdg_environment_defaults

ASSETS_DIR="$DOTFILES_ROOT/assets/macos"

DOCK_APPS=(
    "/System/Applications/Apps.app"
    "/Applications/Safari.app"
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
    "$XCODE_APP"
)

SPOTLIGHT_EXCLUDED_PATHS=(
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$XDG_CACHE_HOME"
)

# Owned by other tools: marked only when present, never pre-created here.
SPOTLIGHT_OPTIONAL_PATHS=(
    "$HOME/Library/Developer/CoreSimulator"
    "$XDG_DATA_HOME/gradle"
    "${ANDROID_HOME:-$HOME/Library/Android/sdk}"
)

rosetta_installed() {
    pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1
}

install_rosetta() {
    info "Installing Rosetta..."
    softwareupdate --install-rosetta --agree-to-license || return 1
    success "Rosetta installed"
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
    # SCcf = search the current folder; PfHm = new windows open at $HOME.
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
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
    defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true

    # Trackpad: the built-in device and an external Magic Trackpad are separate domains.
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
    # false keeps "Displays have separate Spaces" ON; needs a log out.
    defaults write com.apple.spaces spans-displays -bool false

    # Hot corners: 0 = no action.
    local corner
    for corner in tl tr bl br; do
        defaults write com.apple.dock "wvous-${corner}-corner" -int 0
        defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
    done

    # Screenshots
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write com.apple.screencapture type -string "png"
    defaults write com.apple.screencapture disable-shadow -bool true

    # Safari is sandboxed and ignores this domain; use Safari > Settings > Advanced.
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Xcode
    defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool true

    # Tips
    defaults write com.apple.tips TipsEnabled -bool false
    defaults write com.apple.tips CloudKitSyncingEnabled -bool false
    defaults write com.apple.tips NotificationsEnabled -bool false

    # Siri
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    defaults write com.apple.Siri StatusMenuVisible -bool false
    defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false

    # Animation
    defaults write com.apple.universalaccess reduceMotion -bool false
    defaults write com.apple.dock launchanim -bool true
    defaults write com.apple.dock expose-animation-duration -float 0.1
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

    # Time Machine
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
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
    # BSD find matches file flags directly.
    [[ -z "$(find "$HOME/Library" -maxdepth 0 -flags +hidden 2>/dev/null)" ]]
}

unhide_library_folder() {
    info "Unhiding $HOME/Library..."
    chflags nohidden "$HOME/Library"
    success "$HOME/Library is visible in Finder"
}

keyboard_layout_installed() {
    local target="$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    [[ -f "$target" ]] && cmp -s "$ASSETS_DIR/hungarian-win.keylayout" "$target"
}

install_keyboard_layout() {
    info "Installing Hungarian keyboard layout..."
    mkdir -p "$HOME/Library/Keyboard Layouts"
    cp "$ASSETS_DIR/hungarian-win.keylayout" "$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    success "Keyboard layout installed"
}

spotlight_exclusions_applied() {
    local path

    # Check required paths unconditionally: a fresh machine has none of them.
    for path in "${SPOTLIGHT_EXCLUDED_PATHS[@]}"; do
        [[ -f "$path/.metadata_never_index" ]] || return 1
    done

    for path in "${SPOTLIGHT_OPTIONAL_PATHS[@]}"; do
        [[ -d "$path" ]] || continue
        [[ -f "$path/.metadata_never_index" ]] || return 1
    done
}

configure_spotlight_exclusions() {
    info "Excluding high-churn dev paths from Spotlight..."

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

enable_touch_id_sudo() {
    # sudo_local survives OS updates; edits to /etc/pam.d/sudo do not.
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
    # Only Apple's generated "X's Mac" counts as unconfigured (curly apostrophe).
    local current=""
    current="$(scutil --get ComputerName 2>/dev/null)" || return 1
    [[ -n "$current" && "$current" != *"'s "* && "$current" != *"’s "* ]]
}

configure_computer_name() {
    local current="" new="" local_name=""

    if ! is_interactive; then
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

    # LocalHostName is a DNS label: collapse the rest into single hyphens.
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

    # Downloads has to be re-added: --remove all wiped it out.
    dockutil --no-restart --add "$HOME/Downloads" --view auto --display folder --section others >/dev/null

    killall Dock 2>/dev/null || true
    success "Dock layout applied"
}

xcode_first_launch_done() {
    [[ "$(xcode-select -p 2>/dev/null)" == "$XCODE_APP"/* ]] || return 1
    xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1
}

run_xcode_first_launch() {
    info "Running Xcode first-launch setup..."
    sudo -v
    sudo xcode-select -s "$XCODE_APP/Contents/Developer"
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch

    success "Xcode first-launch setup complete"
}

# mas 7 removed the `account` subcommand, so report missing apps instead.
report_missing_app_store_apps() {
    local installed="" id="" name="" missing=()

    command -v mas >/dev/null 2>&1 || return 0
    [[ -f "$DOTFILES_BREWFILE" ]] || return 0

    installed="$(mas list 2>/dev/null | awk '{print $1}')" || return 0

    while read -r id name; do
        grep -qx "$id" <<<"$installed" && continue
        # An app installed outside the App Store has no receipt for mas to list.
        [[ -d "/Applications/$name.app" ]] && continue
        missing+=("$name ($id)")
    done < <(sed -n 's/^mas "\([^"]*\)", id: \([0-9]*\).*/\2 \1/p' "$DOTFILES_BREWFILE")

    if ((${#missing[@]} == 0)); then
        info "All Mac App Store apps installed"
        return 0
    fi

    warn "Mac App Store apps not installed: ${missing[*]}"
    info "Sign in to the App Store, then: brew bundle install --file $DOTFILES_BREWFILE"
}

gh_authenticated() {
    gh auth status >/dev/null 2>&1
}

authenticate_gh() {
    # Not `gh auth setup-git`: it would write a second credential helper into
    # the stowed git config.
    info "Authenticating with GitHub..."
    gh auth login

    success "GitHub authentication configured"
}

# Homebrew llvm ships the binary as llvm-dlltool; Wine's build looks for `dlltool`.
# `brew --prefix <formula>` exits 0 even when uninstalled, so callers test -x.
llvm_dlltool_path() {
    printf '%s/bin/llvm-dlltool\n' "$(brew --prefix llvm 2>/dev/null)"
}

llvm_dlltool_linked() {
    local src=""
    src="$(llvm_dlltool_path)"
    [[ -x "$src" && "$(readlink "$XDG_BIN_HOME/dlltool" 2>/dev/null)" == "$src" ]]
}

link_llvm_dlltool() {
    local src=""
    src="$(llvm_dlltool_path)"
    [[ -x "$src" ]] || {
        warn "Homebrew llvm not installed; skipping dlltool symlink"
        return 1
    }

    mkdir -p "$XDG_BIN_HOME"
    ln -sf "$src" "$XDG_BIN_HOME/dlltool"
    success "Symlinked $XDG_BIN_HOME/dlltool -> $src"
}

main() {
    require_platform macos

    info "macOS setup"

    ensure_xcode_cli_tools

    # First, so every later sudo prompt in this run is a fingerprint.
    offer_if_missing "Enable Touch ID for sudo?" macos_touch_id_sudo_enabled enable_touch_id_sudo "Touch ID for sudo already enabled"

    if [[ "$(uname -m)" == "arm64" ]]; then
        offer_if_missing "Install Rosetta?" rosetta_installed install_rosetta "Rosetta already installed"
    else
        info "Not Apple Silicon; skipping Rosetta"
    fi

    offer_if_missing "Set the computer name?" computer_name_configured configure_computer_name "Computer name already set"

    offer "Apply macOS defaults?" apply_macos_defaults
    offer "Configure power management?" configure_power_management
    require_command dockutil "the Dock layout" && offer "Apply the Dock layout?" configure_dock

    offer_if_missing "Unhide the user Library folder in Finder?" library_folder_visible unhide_library_folder "User Library folder already visible"
    offer_if_missing "Exclude high-churn dev paths from Spotlight?" spotlight_exclusions_applied configure_spotlight_exclusions "Spotlight exclusions already applied"
    offer_if_missing "Install the custom Hungarian keyboard layout?" keyboard_layout_installed install_keyboard_layout "Custom Hungarian keyboard layout already installed"
    offer_if_missing "Symlink LLVM dlltool into $XDG_BIN_HOME for Wine builds?" llvm_dlltool_linked link_llvm_dlltool "LLVM dlltool symlink already in place"

    report_missing_app_store_apps

    if [[ -d "$XCODE_APP" ]]; then
        offer_if_missing "Run Xcode first-launch setup (license, components, xcode-select)?" xcode_first_launch_done run_xcode_first_launch "No pending Xcode first-launch setup"
    else
        info "Xcode not installed; skipping first-launch setup"
    fi

    require_command gh "GitHub authentication" && offer_if_missing "Authenticate the GitHub CLI?" gh_authenticated authenticate_gh "GitHub CLI already authenticated"

    offer_node_toolchain_setup

    # Both scripts self-gate with their own confirm prompt.
    "$DOTFILES_ROOT/scripts/platform/macos-hardening.sh" || warn "macOS hardening did not complete"
    "$DOTFILES_ROOT/scripts/platform/macos-office-tweaks.sh" || warn "Microsoft updater tweaks did not complete"

    success "macOS setup complete"
}

main "$@"
