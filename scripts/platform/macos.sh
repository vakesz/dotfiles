#!/usr/bin/env bash
# Optional macOS setup.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "${BASH_SOURCE[0]%/*}/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-preflight.sh"

set_xdg_environment_defaults

ASSETS_DIR="$DOTFILES_ROOT/assets/macos"
readonly ASSETS_DIR
readonly FUSE_T_CASK="fuse-t"
readonly OMNIMOUNT_APP="/Applications/Omnimount.app"
readonly OMNIMOUNT_REPOSITORY="https://github.com/ramdoor/omnimount.git"
readonly OMNIMOUNT_REVISION="73eed3bb1652eef4a4f60c054214ad4475aa6002"
readonly OMNIMOUNT_BUILD_PATCH="$ASSETS_DIR/omnimount-build.patch"

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
)
readonly DOCK_APPS

SPOTLIGHT_EXCLUDED_PATHS=(
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$XDG_CACHE_HOME"
)
readonly SPOTLIGHT_EXCLUDED_PATHS

# Created by other tools: excluded only if they exist, never created here.
SPOTLIGHT_OPTIONAL_PATHS=(
    "$HOME/Library/Developer/CoreSimulator"
    "$XDG_DATA_HOME/gradle"
    "${ANDROID_HOME:-$HOME/Library/Android/sdk}"
)
readonly SPOTLIGHT_OPTIONAL_PATHS

# Cache brew's prefix once per run instead of forking brew in every helper.
DOTFILES_BREW_PREFIX=""
brew_prefix_once() {
    if [[ -z "$DOTFILES_BREW_PREFIX" ]]; then
        DOTFILES_BREW_PREFIX="$(brew --prefix 2>/dev/null)" || return 1
    fi
    printf '%s\n' "$DOTFILES_BREW_PREFIX"
}

# True when Rosetta's auto-update package is installed.
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
    # SCcf: search the current folder. PfHm: new windows open at $HOME.
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

    # Trackpad. The built-in trackpad and a Magic Trackpad use separate domains.
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
    # false turns "Displays have separate Spaces" on. Applies after logging out.
    defaults write com.apple.spaces spans-displays -bool false

    # Hot corners: 0 means no action.
    local corner
    for corner in tl tr bl br; do
        defaults write com.apple.dock "wvous-${corner}-corner" -int 0
        defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
    done

    # Screenshots
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write com.apple.screencapture type -string "png"
    defaults write com.apple.screencapture disable-shadow -bool true

    # Sandboxed Safari ignores this; use Safari > Settings > Advanced instead.
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
    # BSD find can match file flags directly.
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
    cp -- "$ASSETS_DIR/hungarian-win.keylayout" "$HOME/Library/Keyboard Layouts/Hungarian_Win.keylayout"
    success "Keyboard layout installed"
}

spotlight_exclusions_applied() {
    local path

    # Required paths are always checked; a fresh machine has none of them yet.
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
        # Never create Xcode's DerivedData just to exclude it; only the cache
        # dir (which bootstrap already created) may be created here.
        if [[ "$path" == "$XDG_CACHE_HOME" ]]; then
            mkdir -p -- "$path"
        elif [[ ! -d "$path" ]]; then
            info "Skipping missing directory: $path"
            continue
        fi
        touch -- "$path/.metadata_never_index"
    done

    for path in "${SPOTLIGHT_OPTIONAL_PATHS[@]}"; do
        [[ -d "$path" ]] || continue
        touch -- "$path/.metadata_never_index"
    done

    success "Spotlight exclusions applied"
}

enable_touch_id_sudo() {
    # sudo_local survives macOS updates; edits to /etc/pam.d/sudo don't.
    if [[ ! -f /etc/pam.d/sudo_local.template ]]; then
        warn "/etc/pam.d/sudo_local.template not found; needs macOS 14 or newer"
        return 1
    fi

    info "Enabling Touch ID for sudo..."
    sudo -v
    # Uncomment only the pam_tid line; the template may contain other #auth
    # lines (smartcard, etc.) that must stay disabled.
    sed -E 's/^#[[:space:]]*(auth[^#]*pam_tid\.so.*)/\1/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
    sudo chmod 444 /etc/pam.d/sudo_local

    if ! macos_touch_id_sudo_enabled; then
        error "Touch ID for sudo still reports disabled after the change"
        return 1
    fi

    success "Touch ID for sudo enabled"
}

computer_name_configured() {
    # Apple's default is "<Name>'s <Model>" (either apostrophe style). A custom
    # name containing "'s " (e.g. "Bob's Desktop") still counts as configured
    # unless it ends with a known Apple model suffix.
    local current=""
    current="$(scutil --get ComputerName 2>/dev/null)" || return 1
    [[ -n "$current" ]] || return 1
    if [[ "$current" == *"'s "* || "$current" == *"’s "* ]]; then
        [[ "$current" != *" Mac" && "$current" != *"MacBook"* && "$current" != *"iMac"* && "$current" != *"Mac mini"* && "$current" != *"Mac Pro"* && "$current" != *"Mac Studio"* ]] || return 1
    fi
    return 0
}

configure_computer_name() {
    local current="" new="" local_name=""
    local timeout="${DOTFILES_CONFIRM_TIMEOUT:-30}"

    if ! is_interactive; then
        info "Non-interactive shell; skipping computer name"
        return 0
    fi

    [[ "$timeout" =~ ^[0-9]+$ ]] || timeout=30
    [[ "$timeout" == "0" ]] && timeout=30

    current="$(scutil --get ComputerName 2>/dev/null || printf '%s' "unknown")"
    printf '\nComputer name [%s]: ' "$current"
    if ! IFS= read -r -t "$timeout" new; then
        printf '\n'
        info "No input; keeping the current computer name"
        return 0
    fi

    if [[ -z "$new" ]]; then
        info "Keeping the current computer name"
        return 0
    fi

    # LocalHostName must be a DNS label, so turn everything else into hyphens.
    # NetBIOS names are limited to 15 chars, so truncate there too.
    local_name="$(printf '%s' "$new" | sed -E 's/[^a-zA-Z0-9]+/-/g; s/^-+//; s/-+$//' | tr '[:upper:]' '[:lower:]' | cut -c1-15 | sed -E 's/-+$//')"
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
    dockutil --no-restart --remove all 2>&1 | grep -v '^$' >/dev/null || true

    for app in "${DOCK_APPS[@]}"; do
        if [[ ! -d "$app" ]]; then
            warn "Not installed, skipping in Dock: $app"
            continue
        fi
        dockutil --no-restart --add "$app" >/dev/null || warn "Failed to add to Dock: $app"
    done

    # --remove all also removed Downloads, so add it back.
    dockutil --no-restart --add "$HOME/Downloads" --view auto --display folder --section others >/dev/null || warn "Failed to re-add Downloads to Dock"

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

# mas 7 removed `account`, so report missing apps instead of checking sign-in.
report_missing_app_store_apps() {
    local installed="" id="" name="" missing=()

    command -v mas >/dev/null 2>&1 || return 0
    [[ -f "$DOTFILES_BREWFILE" ]] || return 0

    if ! installed="$(mas list 2>/dev/null | awk '{print $1}')"; then
        warn "Could not list Mac App Store apps; is mas working and signed in?"
        return 0
    fi

    while read -r id name; do
        grep -qx -- "$id" <<<"$installed" && continue
        # Apps installed outside the App Store have no receipt for mas to list.
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
    # Not `gh auth setup-git`: it would add a second credential helper to the
    # stowed git config.
    info "Authenticating with GitHub..."
    gh auth login

    success "GitHub authentication configured"
}

rustup_path() {
    local prefix=""
    prefix="$(brew_prefix_once 2>/dev/null)" || return 1
    printf '%s/opt/rustup/bin/rustup\n' "$prefix"
}

rustup_stable_toolchain_installed() {
    local rustup_bin=""

    rustup_bin="$(rustup_path)"
    [[ -x "$rustup_bin" ]] || return 1
    "$rustup_bin" toolchain list | grep -q '^stable'
}

install_rustup_stable_toolchain() {
    local rustup_bin=""

    rustup_bin="$(rustup_path)"
    [[ -x "$rustup_bin" ]] || {
        warn "Homebrew rustup not installed; skipping Rust setup"
        return 1
    }

    info "Installing the stable Rust toolchain..."
    "$rustup_bin" default stable
    success "Stable Rust toolchain installed"
}

# Homebrew llvm names it llvm-dlltool, but Wine's build looks for `dlltool`.
# Callers check -x since the path may not exist when llvm isn't installed.
llvm_dlltool_path() {
    local prefix=""
    prefix="$(brew_prefix_once 2>/dev/null)" || return 1
    printf '%s/opt/llvm/bin/llvm-dlltool\n' "$prefix"
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

    mkdir -p -- "$XDG_BIN_HOME"
    ln -sf -- "$src" "$XDG_BIN_HOME/dlltool"
    success "Symlinked $XDG_BIN_HOME/dlltool -> $src"
}

# Verify that FUSE-T, the Omnimount CLI, and the app are all installed.
omnimount_installed() {
    local brew_prefix=""

    [[ "${OMNIMOUNT_REBUILD:-0}" != "1" ]] || return 1
    brew_prefix="$(brew_prefix_once 2>/dev/null)" || return 1
    brew list --cask "$FUSE_T_CASK" >/dev/null 2>&1 || return 1
    [[ -x "$brew_prefix/bin/omnimount" && -x "$brew_prefix/sbin/fuse2fs" && -d "$OMNIMOUNT_APP" ]]
}

# Apply local compatibility fixes before building Omnimount.
apply_omnimount_build_patch() {
    local source_dir="$1"

    /usr/bin/patch --directory "$source_dir" --strip=1 --batch --forward <"$OMNIMOUNT_BUILD_PATCH"
}

install_omnimount() {
    local brew_prefix="" build_arch="" build_dir="" scratch_dir="" source_dir="" work_dir=""

    brew_prefix="$(brew_prefix_once 2>/dev/null)" || {
        warn "Homebrew is required to install Omnimount"
        return 1
    }

    if ! brew list --cask "$FUSE_T_CASK" >/dev/null 2>&1; then
        warn "FUSE-T is not installed; rerun ./bootstrap.sh to install the Brewfile first"
        return 1
    fi

    require_command git "Omnimount" || return 1
    require_command make "Omnimount" || return 1
    require_command pkg-config "Omnimount FUSE-T builds" || return 1
    [[ -r "$OMNIMOUNT_BUILD_PATCH" ]] || {
        error "Missing Omnimount build compatibility patch: $OMNIMOUNT_BUILD_PATCH"
        return 1
    }

    work_dir="$(mktemp -d "${TMPDIR:-/tmp}/omnimount.XXXXXX")" || {
        error "Could not create a temporary directory for Omnimount"
        return 1
    }
    source_dir="$work_dir/source"
    build_dir="$work_dir/build"
    scratch_dir="$work_dir/swift-build"

    if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]; then
        build_arch="arm64"
    else
        build_arch="x86_64"
    fi

    info "Building Omnimount for $build_arch with FUSE-T (temporary files are removed afterward)..."
    if ! (
        trap 'rm -rf -- "$work_dir"' EXIT
        export OMNIMOUNT_ARCH="$build_arch" BACKEND="fuse-t"
        mkdir -p "$build_dir" "$scratch_dir" &&
            git clone --no-checkout --depth 1 "$OMNIMOUNT_REPOSITORY" "$source_dir" &&
            git -C "$source_dir" fetch --depth 1 origin "$OMNIMOUNT_REVISION" &&
            git -C "$source_dir" checkout --detach FETCH_HEAD &&
            apply_omnimount_build_patch "$source_dir" &&
            TMPDIR="$build_dir" make -C "$source_dir" "PREFIX=$brew_prefix" fuse2fs &&
            TMPDIR="$build_dir" make -C "$source_dir" "PREFIX=$brew_prefix" ntfs3g &&
            TMPDIR="$build_dir" SCRATCH="$scratch_dir" OMNIMOUNT_SCRATCH="$scratch_dir" \
                make -j1 -C "$source_dir" "PREFIX=$brew_prefix" install
    ); then
        error "Omnimount installation failed"
        return 1
    fi

    success "Omnimount installed"
    "$brew_prefix/bin/omnimount" doctor || warn "Omnimount doctor reported an issue; finish the permissions below, then run: omnimount doctor"

    open "$OMNIMOUNT_APP" || warn "Could not open Omnimount automatically; open $OMNIMOUNT_APP manually"
}

omnimount_setup_notes() {
    info "Omnimount manual setup checklist (macOS permissions cannot be granted automatically):"
    info "1. Open $OMNIMOUNT_APP, open Setup from its menu bar icon, and activate the helper."
    info "2. System Settings > General > Login Items & Extensions (Login Items on older macOS): allow Omnimount in the background."
    info "3. System Settings > Privacy & Security > Full Disk Access: click +, then Cmd+Shift+G, and add $OMNIMOUNT_APP/Contents/MacOS/OmnimountHelper. Enable its switch."
    info "4. If the helper was already running, restart it after granting access or rebuilding: sudo launchctl kickstart -k system/org.omnimount.helper"
    info "FUSE-T needs no kernel extension, Reduced Security, or Recovery-mode changes. Do not install macFUSE alongside it."
    info "Connect a drive, dismiss any macOS Initialize prompt, and mount its ext2/3/4 or NTFS partition from Omnimount's menu. Eject before unplugging."
    info "If NTFS stays read-only, fully shut down Windows with Fast Startup/hibernation disabled and check the filesystem there before retrying."
    info "For sudo CLI use, also grant Full Disk Access to your terminal and $(brew --prefix)/bin/omnimount. Run omnimount doctor and omnimount list; doctor checks tools, not permissions."
}

main() {
    require_platform macos

    info "macOS setup"

    ensure_xcode_cli_tools

    # Do this first so every later sudo prompt can use Touch ID.
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
    offer_if_missing "Install Omnimount for ext2/3/4 and NTFS disks?" omnimount_installed install_omnimount "Omnimount already installed"

    report_missing_app_store_apps

    if [[ -d "$XCODE_APP" ]]; then
        offer_if_missing "Run Xcode first-launch setup (license, components, xcode-select)?" xcode_first_launch_done run_xcode_first_launch "No pending Xcode first-launch setup"
    else
        info "Xcode not installed; skipping first-launch setup"
    fi

    require_command gh "GitHub authentication" && offer_if_missing "Authenticate the GitHub CLI?" gh_authenticated authenticate_gh "GitHub CLI already authenticated"

    offer_if_missing "Install the stable Rust toolchain?" rustup_stable_toolchain_installed install_rustup_stable_toolchain "Stable Rust toolchain already installed"

    # Both scripts ask for confirmation themselves.
    "$DOTFILES_ROOT/scripts/platform/macos-hardening.sh" || warn "macOS hardening did not complete"
    "$DOTFILES_ROOT/scripts/platform/macos-office-tweaks.sh" || warn "Microsoft updater tweaks did not complete"

    if [[ -d "$OMNIMOUNT_APP" ]]; then
        omnimount_setup_notes
    fi
    success "macOS setup complete"
}

main "$@"
