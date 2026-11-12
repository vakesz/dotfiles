#!/usr/bin/env bash
# Optional Omnimount install for ext2/3/4 and NTFS disks, built against FUSE-T.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"

readonly FUSE_T_CASK="fuse-t"
readonly OMNIMOUNT_APP="/Applications/Omnimount.app"
readonly OMNIMOUNT_REPOSITORY="https://github.com/ramdoor/omnimount.git"
readonly OMNIMOUNT_REVISION="73eed3bb1652eef4a4f60c054214ad4475aa6002"
readonly OMNIMOUNT_BUILD_PATCH="$DOTFILES_ROOT/assets/macos/omnimount-build.patch"

# Verify that FUSE-T, the Omnimount CLI, and the app are all installed.
omnimount_installed() {
    local brew_prefix=""

    [[ "${OMNIMOUNT_REBUILD:-0}" != "1" ]] || return 1
    macos_brew_prefix || return 1
    brew_prefix="$MACOS_BREW_PREFIX"
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

    macos_brew_prefix || {
        warn "Homebrew is required to install Omnimount"
        return 1
    }
    brew_prefix="$MACOS_BREW_PREFIX"

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

    if macos_apple_silicon; then
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
    info "For sudo CLI use, also grant Full Disk Access to your terminal and ${MACOS_BREW_PREFIX:-}/bin/omnimount. Run omnimount doctor and omnimount list; doctor checks tools, not permissions."
}

main() {
    require_platform macos

    info "Omnimount (ext2/3/4 and NTFS disks)"

    # Fill the brew prefix cache here, in the parent shell; offered actions run
    # in subshells. Brew may be absent, which the steps below handle.
    macos_brew_prefix || true

    offer_if_missing "Install Omnimount for ext2/3/4 and NTFS disks?" omnimount_installed install_omnimount "Omnimount already installed"

    if [[ -d "$OMNIMOUNT_APP" ]]; then
        omnimount_setup_notes
    fi
}

main "$@"
