#!/usr/bin/env bash
# Optional macOS setup.

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-defaults.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-preflight.sh"

set_xdg_environment_defaults

ASSETS_DIR="$DOTFILES_ROOT/assets/macos"
readonly ASSETS_DIR

# True when Rosetta's auto-update package is installed.
rosetta_installed() {
    pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1
}

install_rosetta() {
    info "Installing Rosetta..."
    softwareupdate --install-rosetta --agree-to-license || return 1
    success "Rosetta installed"
}

# Write the rows of lib/macos-defaults.sh that differ, then read them back.
# offer_if_missing skips this step, and so the Finder and Dock restarts, when
# nothing differs.
apply_macos_defaults() {
    local scope domain key type value have failed=0 spaces=0

    info "Applying macOS defaults..."

    # Keep going past a domain macOS refuses and report it at the end.
    while IFS='|' read -r scope domain key type value have; do
        info "$domain $key: $have -> $value"
        if ! macos_defaults_write "$scope" "$domain" "$key" "$type" "$value"; then
            warn "Could not write $domain $key"
            failed=1
        fi
        if [[ "$key" == "spans-displays" ]]; then
            spaces=1
        fi
    done < <(macos_defaults_drift)

    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    while IFS='|' read -r scope domain key type value have; do
        error "$domain $key is still $have, expected $value"
        failed=1
    done < <(macos_defaults_drift)

    ((failed == 0)) || return 1

    success "macOS defaults applied"
    if ((spaces)); then
        info "Separate Spaces per display takes effect after the next log out"
    fi
}

# Desktops have no battery, and `pmset -b` fails there.
has_battery() {
    pmset -g batt 2>/dev/null | grep -q InternalBattery
}

configure_power_management() {
    info "Configuring power management..."

    sudo -v
    if has_battery; then
        sudo pmset -b sleep 60 displaysleep 15
    fi
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
    local current="" new="" local_name="" timeout=""

    if ! is_interactive; then
        info "Non-interactive shell; skipping computer name"
        return 0
    fi

    timeout="$(prompt_timeout)"

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
    # Fails on an already empty Dock, which is fine.
    dockutil --no-restart --remove all >/dev/null 2>&1 || true

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

    has_command mas || return 0
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

# Homebrew's rustup is keg-only, so call it by its opt path. main fills
# MACOS_BREW_PREFIX first; it stays empty when brew is missing.
rustup_bin() {
    printf '%s/opt/rustup/bin/rustup\n' "$MACOS_BREW_PREFIX"
}

rustup_stable_toolchain_installed() {
    [[ -n "$MACOS_BREW_PREFIX" && -x "$(rustup_bin)" ]] || return 1
    "$(rustup_bin)" toolchain list | grep -q '^stable'
}

install_rustup_stable_toolchain() {
    [[ -n "$MACOS_BREW_PREFIX" && -x "$(rustup_bin)" ]] || {
        warn "Homebrew rustup not installed; skipping Rust setup"
        return 1
    }

    info "Installing the stable Rust toolchain..."
    "$(rustup_bin)" default stable
    success "Stable Rust toolchain installed"
}

# Homebrew llvm names it llvm-dlltool, but Wine's build looks for `dlltool`.
llvm_dlltool_src() {
    printf '%s/opt/llvm/bin/llvm-dlltool\n' "$MACOS_BREW_PREFIX"
}

llvm_dlltool_linked() {
    [[ -n "$MACOS_BREW_PREFIX" && -x "$(llvm_dlltool_src)" ]] || return 1
    [[ "$(readlink "$XDG_BIN_HOME/dlltool" 2>/dev/null)" == "$(llvm_dlltool_src)" ]]
}

link_llvm_dlltool() {
    local src=""

    src="$(llvm_dlltool_src)"
    [[ -n "$MACOS_BREW_PREFIX" && -x "$src" ]] || {
        warn "Homebrew llvm not installed; skipping dlltool symlink"
        return 1
    }

    mkdir -p -- "$XDG_BIN_HOME"
    ln -sf -- "$src" "$XDG_BIN_HOME/dlltool"
    success "Symlinked $XDG_BIN_HOME/dlltool -> $src"
}

# GUI apps get /usr/bin:/bin:/usr/sbin:/sbin by default, so editors and IDEs
# can't find brew's cargo, rustc, node or pnpm. `launchctl config user path`
# stores the PATH in launchd itself, so it needs no LaunchAgent and applies to
# every app, including login items. launchd can't persist other variables, so
# tools GUI apps run must work with their default homes (Rust uses ~/.rustup
# and ~/.cargo for this reason).
configure_gui_path() {
    local p=""
    p="$(macos_gui_path)" || {
        warn "Couldn't build the PATH from ~/.zshenv"
        return 1
    }

    sudo launchctl config user path "$p" || {
        warn "launchctl config user path failed"
        return 1
    }
    success "Set the GUI app PATH; reboot for it to take effect"
}

main() {
    require_platform macos

    info "macOS setup"

    ensure_xcode_cli_tools

    # Fill the brew prefix cache here, in the parent shell; offered actions run
    # in subshells. Brew may be absent, which later steps handle themselves.
    macos_brew_prefix || true

    # Do this first so every later sudo prompt can use Touch ID.
    offer_if_missing "Enable Touch ID for sudo?" macos_touch_id_sudo_enabled enable_touch_id_sudo "Touch ID for sudo already enabled"

    if macos_apple_silicon; then
        offer_if_missing "Install Rosetta?" rosetta_installed install_rosetta "Rosetta already installed"
    else
        info "Not Apple Silicon; skipping Rosetta"
    fi

    offer_if_missing "Set the computer name?" computer_name_configured configure_computer_name "Computer name already set"

    offer_if_missing "Apply macOS defaults?" macos_defaults_applied apply_macos_defaults "macOS defaults already applied"
    offer "Configure power management?" configure_power_management
    require_command dockutil "the Dock layout" && offer "Apply the Dock layout?" configure_dock

    offer_if_missing "Give GUI apps the ~/.zshenv PATH (needs sudo and a reboot)?" macos_gui_path_configured configure_gui_path "GUI app PATH already set"
    offer_if_missing "Unhide the user Library folder in Finder?" library_folder_visible unhide_library_folder "User Library folder already visible"
    offer_if_missing "Install the custom Hungarian keyboard layout?" keyboard_layout_installed install_keyboard_layout "Custom Hungarian keyboard layout already installed"
    offer_if_missing "Symlink LLVM dlltool into $XDG_BIN_HOME for Wine builds?" llvm_dlltool_linked link_llvm_dlltool "LLVM dlltool symlink already in place"
    # Each sub-script asks for confirmation itself and can also run alone.
    "$DOTFILES_ROOT/scripts/platform/macos-spotlight.sh" || warn "Spotlight setup did not complete"
    # Also prints the Omnimount permissions checklist.
    "$DOTFILES_ROOT/scripts/platform/macos-omnimount.sh" || warn "Omnimount setup did not complete"

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

    success "macOS setup complete"
}

main "$@"
