#!/usr/bin/env bash
# Install Omnimount for ext2/3/4 and NTFS disks on FUSE-T.
# A notarized app from the pinned upstream team is linked into the Homebrew
# prefix. Source builds run only when no notarized app is installed.

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/paths.sh"
source "$DOTFILES_ROOT/scripts/lib/ui.sh"
source "$DOTFILES_ROOT/scripts/lib/platform.sh"
source "$DOTFILES_ROOT/scripts/lib/macos-state.sh"

# FUSE_T_CASK, FUSE_T_LIB, MACFUSE_FS and OMNIMOUNT_APP come from macos-state.sh.
readonly OMNIMOUNT_REPOSITORY="https://github.com/ramdoor/omnimount.git"
# v0.4.8 (2026-11-15). Upstream publishes no release archive, so this is the
# source pin for machines without the notarized app.
readonly OMNIMOUNT_REVISION="d15fad6a5ddb15df6bde32fa1490a668f5acd1a8"
readonly OMNIMOUNT_VERSION="0.4.8"
# Developer ID team that signs the upstream notarized app.
readonly OMNIMOUNT_TEAM_ID="5QH6VFV9X3"
readonly OMNIMOUNT_BUILD_PATCH="$DOTFILES_ROOT/assets/macos/omnimount-build.patch"
# e2fsprogs sha256 matches kernel.org sha256sums.asc. The ntfs-3g sha256 is the
# tarball at NTFS3G_URL, which is the URL this Omnimount revision downloads.
readonly E2FSPROGS_VERSION="1.47.3"
readonly E2FSPROGS_SHA256="857e6ef800feaa2bb4578fbc810214be5d3c88b072ea53c5384733a965737329"
readonly E2FSPROGS_URL="https://mirrors.edge.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.xz"
readonly NTFS3G_VERSION="2026.7.7"
readonly NTFS3G_SHA256="d67b769025d32860549d35c2147e45024d172f81c540d750390ce3602c059dab"
readonly NTFS3G_URL="https://tuxera.com/opensource/ntfs-3g_ntfsprogs-2026.7.7.tgz"

# Native architecture, including under Rosetta. `uname -m` would report x86_64.
omnimount_arch() {
    if macos_apple_silicon; then
        printf 'arm64\n'
    else
        printf 'x86_64\n'
    fi
}

# Stamp and build log directory. main sets the XDG defaults first.
omnimount_state_dir() {
    printf '%s\n' "$XDG_STATE_HOME/omnimount"
}

# "fuse-t 1.2.9" -> "1.2.9". Empty when the cask is absent.
omnimount_fuse_t_version() {
    local line=""

    line="$(brew list --cask --versions "$FUSE_T_CASK" 2>/dev/null)" || return 1
    [[ -n "$line" ]] || return 1
    printf '%s\n' "${line##* }"
}

# Same identity the Omnimount Makefile signs with. "-" means ad-hoc.
omnimount_sign_id() {
    local id=""

    id="$(security find-identity -v -p codesigning 2>/dev/null | awk -F '"' 'NR==1 {print $2}')"
    if [[ -z "$id" ]]; then
        printf '%s\n' "-"
    else
        printf '%s\n' "$id"
    fi
}

# Print the TeamIdentifier codesign reports for $1. Fails for an unsigned
# binary (codesign exits 1) and for an ad-hoc one, which codesign reports as
# "TeamIdentifier=not set" with exit 0.
omnimount_team_id() {
    local details="" line=""

    details="$(codesign -dv "$1" 2>&1)" || return 1
    while IFS= read -r line; do
        if [[ "$line" == TeamIdentifier=* && "$line" != "TeamIdentifier=not set" ]]; then
            printf '%s\n' "${line#TeamIdentifier=}"
            return 0
        fi
    done <<<"$details"
    return 1
}

# True when both paths exist and resolve to the same file.
omnimount_same_file() {
    local left="" right=""

    [[ -e "$1" && -e "$2" ]] || return 1
    left="$(realpath "$1")" || return 1
    right="$(realpath "$2")" || return 1
    [[ "$left" == "$right" ]]
}

# A stapled ticket means this is a notarized app, not a local build. Replacing
# it would change the signing identity and drop Full Disk Access. Any
# developer can notarize an app, so omnimount_app_trusted pins the team too.
omnimount_app_notarized() {
    local details=""

    [[ -d "$OMNIMOUNT_APP" ]] || return 1
    details="$(codesign -dv --verbose=4 "$OMNIMOUNT_APP" 2>&1)" || return 1
    [[ "$details" == *"Notarization Ticket=stapled"* ]]
}

# True when the app is signed by the upstream team.
omnimount_app_team_pinned() {
    [[ "$(omnimount_team_id "$OMNIMOUNT_APP")" == "$OMNIMOUNT_TEAM_ID" ]]
}

# Full check before linking: pinned team, an intact signature, and a
# Gatekeeper assessment that accepts it as notarized Developer ID software.
omnimount_app_trusted() {
    local team="" assessment=""

    team="$(omnimount_team_id "$OMNIMOUNT_APP")" || team="none"
    if [[ "$team" != "$OMNIMOUNT_TEAM_ID" ]]; then
        error "$OMNIMOUNT_APP is signed by team $team, not the upstream team $OMNIMOUNT_TEAM_ID; not linking it"
        return 1
    fi
    if ! codesign --verify --strict "$OMNIMOUNT_APP" 2>/dev/null; then
        error "$OMNIMOUNT_APP fails codesign --verify --strict; reinstall it"
        return 1
    fi
    if ! assessment="$(spctl -a -vv "$OMNIMOUNT_APP" 2>&1)" ||
        [[ "$assessment" != *"source=Notarized Developer ID"* ]]; then
        error "Gatekeeper does not accept $OMNIMOUNT_APP as notarized Developer ID software"
        printf '%s\n' "$assessment" >&2
        return 1
    fi
}

omnimount_links_current() {
    omnimount_same_file "$MACOS_BREW_PREFIX/bin/omnimount" "$OMNIMOUNT_APP/Contents/MacOS/omnimount-cli" &&
        omnimount_same_file "$MACOS_BREW_PREFIX/sbin/fuse2fs" "$OMNIMOUNT_APP/Contents/MacOS/fuse2fs"
}

omnimount_fuse_t_ready() {
    macos_fuse_t_cask_installed && macos_fuse_t_lib_present
}

# Source install is current when the stamp matches this pin, this Mac, the
# installed FUSE-T, and the codesigning identity a rebuild would use.
omnimount_source_current() {
    local file="" revision="" arch="" fuse_t="" sign_id="" app_version=""
    local cli_version="" expected_arch="" expected_fuse="" expected_sign="" key="" value=""

    file="$(omnimount_state_dir)/build.stamp"
    [[ -f "$file" ]] || return 1
    while IFS='=' read -r key value; do
        case "$key" in
            revision) revision="$value" ;;
            arch) arch="$value" ;;
            fuse_t) fuse_t="$value" ;;
            sign_id) sign_id="$value" ;;
            app_version) app_version="$value" ;;
        esac
    done <"$file"

    [[ "$revision" == "$OMNIMOUNT_REVISION" ]] || return 1
    expected_arch="$(omnimount_arch)"
    [[ "$arch" == "$expected_arch" ]] || return 1
    expected_fuse="$(omnimount_fuse_t_version)" || return 1
    [[ "$fuse_t" == "$expected_fuse" ]] || return 1
    expected_sign="$(omnimount_sign_id)"
    [[ "$sign_id" == "$expected_sign" ]] || return 1
    [[ -n "$app_version" ]] || return 1
    [[ "$(macos_omnimount_app_version)" == "$app_version" ]] || return 1
    cli_version="$(macos_omnimount_cli_version "$MACOS_BREW_PREFIX/bin/omnimount")" || return 1
    [[ "$cli_version" == "$app_version" ]]
}

# True when FUSE-T is present and either the upstream notarized app is linked
# or the source stamp still matches. OMNIMOUNT_REBUILD=1 forces another pass.
omnimount_installed() {
    local app_version="" cli_version=""

    [[ "${OMNIMOUNT_REBUILD:-0}" != "1" ]] || return 1
    macos_brew_prefix || return 1
    omnimount_fuse_t_ready || return 1
    if macos_macfuse_present; then
        return 1
    fi

    if omnimount_app_notarized; then
        omnimount_app_team_pinned || return 1
        omnimount_links_current || return 1
        app_version="$(macos_omnimount_app_version)" || return 1
        cli_version="$(macos_omnimount_cli_version "$MACOS_BREW_PREFIX/bin/omnimount")" || return 1
        [[ "$app_version" == "$cli_version" ]]
        return
    fi

    [[ -x "$MACOS_BREW_PREFIX/bin/omnimount" && -x "$MACOS_BREW_PREFIX/sbin/fuse2fs" && -d "$OMNIMOUNT_APP" ]] || return 1
    omnimount_source_current
}

# Record what a source build was built against. Notarized installs need no
# stamp: their symlinks follow the app.
omnimount_write_stamp() {
    local dir="" arch="" fuse_t="" app_version=""

    dir="$(omnimount_state_dir)"
    mkdir -p -- "$dir" || return 1
    arch="$(omnimount_arch)"
    fuse_t="$(omnimount_fuse_t_version)" || return 1
    app_version="$(macos_omnimount_app_version)" || return 1

    {
        printf 'revision=%s\n' "$OMNIMOUNT_REVISION"
        printf 'arch=%s\n' "$arch"
        printf 'fuse_t=%s\n' "$fuse_t"
        printf 'sign_id=%s\n' "$(omnimount_sign_id)"
        printf 'app_version=%s\n' "$app_version"
    } >"$dir/build.stamp" || return 1
}

# Point the Homebrew paths at the notarized app. Those paths are not brew-owned.
omnimount_link_notarized() {
    local brew_prefix="$1"
    local cli_src="$OMNIMOUNT_APP/Contents/MacOS/omnimount-cli"
    local fuse_src="$OMNIMOUNT_APP/Contents/MacOS/fuse2fs"
    local cli_dst="$brew_prefix/bin/omnimount"
    local fuse_dst="$brew_prefix/sbin/fuse2fs"
    local replaced=0

    omnimount_app_trusted || return 1
    [[ -x "$cli_src" && -x "$fuse_src" ]] || {
        error "The notarized Omnimount app is missing omnimount-cli or fuse2fs"
        return 1
    }
    if [[ -e "$cli_dst" || -L "$cli_dst" ]] && ! omnimount_same_file "$cli_dst" "$cli_src"; then
        replaced=1
    fi

    mkdir -p -- "$brew_prefix/bin" "$brew_prefix/sbin" || return 1
    ln -sfn -- "$cli_src" "$cli_dst" || return 1
    ln -sfn -- "$fuse_src" "$fuse_dst" || return 1
    # A stamp only describes a source build, which these links replace.
    rm -f -- "$(omnimount_state_dir)/build.stamp"
    success "Linked ${cli_dst} to the notarized Omnimount $(macos_omnimount_app_version)"
    if ((replaced)); then
        warn "The CLI binary changed. Grant Full Disk Access to ${cli_dst} again if sudo omnimount cannot see disks."
    fi
    "$cli_dst" doctor || warn "Omnimount doctor reported an issue; finish the permissions below, then run: omnimount doctor"
    omnimount_open_app
}

omnimount_require_build_tools() {
    local tool=""

    for tool in git make pkg-config python3 curl swift; do
        require_command "$tool" "an Omnimount source build" || return 1
    done
    [[ -r "$OMNIMOUNT_BUILD_PATCH" ]] || {
        error "Missing Omnimount build compatibility patch: $OMNIMOUNT_BUILD_PATCH"
        return 1
    }
}

# `make install` deletes /Applications/Omnimount.app. A running app or helper
# turns that into a half-deleted bundle.
omnimount_refuse_if_running() {
    if pgrep -qx Omnimount || pgrep -qx OmnimountHelper; then
        error "Quit Omnimount and its helper before a source install. Replacing /Applications/Omnimount.app while either is running leaves a broken bundle."
        return 1
    fi
}

omnimount_fetch_verified() {
    local url="$1" digest="$2" dest="$3"
    local partial="" actual=""

    partial="${dest}.partial"
    # `if` so a refused URL still cleans up when the caller has set -e disabled.
    if ! curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' \
        --retry 3 --retry-delay 2 --output "$partial" -- "$url"; then
        rm -f -- "$partial"
        error "Download failed for ${url##*/}"
        return 1
    fi
    actual="$(shasum -a 256 "$partial" | awk '{print $1}')" || {
        rm -f -- "$partial"
        return 1
    }
    if [[ "$actual" != "$digest" ]]; then
        rm -f -- "$partial"
        error "Checksum mismatch for ${url##*/}"
        return 1
    fi
    mv -- "$partial" "$dest" || return 1
}

# Download the two upstream tarballs, verify them, and export the source dirs
# the v0.4.8 build scripts honor instead of curling the archives themselves.
omnimount_prepare_sources() {
    local src_root="$1"
    local e2_tar="$src_root/e2fsprogs-${E2FSPROGS_VERSION}.tar.xz"
    local nt_tar="$src_root/ntfs-3g_ntfsprogs-${NTFS3G_VERSION}.tgz"
    local e2_dir="$src_root/e2fsprogs-${E2FSPROGS_VERSION}"
    local nt_dir="$src_root/ntfs-3g-${NTFS3G_VERSION}"

    omnimount_fetch_verified "$E2FSPROGS_URL" "$E2FSPROGS_SHA256" "$e2_tar" || return 1
    omnimount_fetch_verified "$NTFS3G_URL" "$NTFS3G_SHA256" "$nt_tar" || return 1
    tar -xf "$e2_tar" -C "$src_root" || return 1
    tar -xf "$nt_tar" -C "$src_root" || return 1
    [[ -f "$e2_dir/configure" && -f "$nt_dir/configure" ]] || {
        error "Verified archives did not contain the expected Omnimount dependency sources"
        return 1
    }
    E2FSPROGS_SOURCE_DIR="$e2_dir"
    NTFS3G_SOURCE_DIR="$nt_dir"
    export E2FSPROGS_SOURCE_DIR NTFS3G_SOURCE_DIR
}

# Fail with a rebase hint before compiling. --fuzz=0 rejects a drifted context.
apply_omnimount_build_patch() {
    local source_dir="$1"

    if ! /usr/bin/patch --directory "$source_dir" --strip=1 --forward --dry-run --fuzz=0 <"$OMNIMOUNT_BUILD_PATCH"; then
        error "Omnimount build patch does not apply to ${OMNIMOUNT_REVISION:0:12}; rebase $OMNIMOUNT_BUILD_PATCH"
        return 1
    fi
    /usr/bin/patch --directory "$source_dir" --strip=1 --batch --forward --fuzz=0 <"$OMNIMOUNT_BUILD_PATCH"
}

# Build inside work_dir. OMNIMOUNT_KEEP=1 leaves the tree in place on exit.
omnimount_run_build() {
    local work_dir="$1" brew_prefix="$2" build_arch="$3"
    local source_dir="$work_dir/source"
    local build_dir="$work_dir/build"
    local scratch_dir="$work_dir/swift-build"
    local sources_dir="$work_dir/sources"
    local keep_message="" quoted_dir=""
    local head=""

    # The caller runs this function in a pipeline after `set +e`, so the
    # subshell inherits that. Turn strict mode back on or a failed compile
    # continues into the next step.
    set -euo pipefail

    quoted_dir="$(printf '%q' "$work_dir")"
    if [[ "${OMNIMOUNT_KEEP:-0}" == "1" ]]; then
        keep_message="$(printf '%q' "Keeping Omnimount build tree at ${work_dir}")"
        # shellcheck disable=SC2064 # capture this path; the trap runs after the function returns
        trap "info ${keep_message}" EXIT
    else
        # shellcheck disable=SC2064 # capture this path; the trap runs after the function returns
        trap "rm -rf -- ${quoted_dir}" EXIT
    fi

    mkdir -p -- "$build_dir" "$scratch_dir" "$sources_dir"
    omnimount_prepare_sources "$sources_dir"
    export GIT_TERMINAL_PROMPT=0
    git clone --no-checkout --depth 1 "$OMNIMOUNT_REPOSITORY" "$source_dir"
    git -C "$source_dir" fetch --depth 1 origin "$OMNIMOUNT_REVISION"
    git -C "$source_dir" checkout --detach FETCH_HEAD
    head="$(git -C "$source_dir" rev-parse HEAD)"
    [[ "$head" == "$OMNIMOUNT_REVISION" ]] || {
        error "Checked out ${head:0:12}, expected ${OMNIMOUNT_REVISION:0:12}"
        return 1
    }
    apply_omnimount_build_patch "$source_dir"

    export OMNIMOUNT_ARCH="$build_arch" BACKEND="fuse-t"
    # Versions are readonly; export them without assigning. The build dirs are not.
    export E2FSPROGS_VERSION NTFS3G_VERSION
    E2FSPROGS_BUILD_DIR="$build_dir/e2fsprogs"
    NTFS3G_BUILD_DIR="$build_dir/ntfs3g"
    export E2FSPROGS_BUILD_DIR NTFS3G_BUILD_DIR
    TMPDIR="$build_dir" make -C "$source_dir" "PREFIX=$brew_prefix" fuse2fs
    TMPDIR="$build_dir" make -C "$source_dir" "PREFIX=$brew_prefix" ntfs3g
    TMPDIR="$build_dir" SCRATCH="$scratch_dir" OMNIMOUNT_SCRATCH="$scratch_dir" \
        make -j1 -C "$source_dir" "PREFIX=$brew_prefix" install
}

omnimount_warn_if_adhoc() {
    if ! omnimount_team_id "$1" >/dev/null; then
        warn "Omnimount is ad-hoc signed. Full Disk Access will not survive the next rebuild until a codesigning identity is in the keychain."
    fi
}

# Passwordless sudo only. A prompt here would stall bootstrap.
omnimount_restart_helper() {
    if ! launchctl print system/org.omnimount.helper >/dev/null 2>&1; then
        return 0
    fi
    if sudo -n launchctl kickstart -k system/org.omnimount.helper >/dev/null 2>&1; then
        info "Restarted the Omnimount helper"
        return 0
    fi
    info "The Omnimount helper is loaded. After granting access, restart it: sudo launchctl kickstart -k system/org.omnimount.helper"
}

omnimount_open_app() {
    if ! is_interactive; then
        return 0
    fi
    if pgrep -qx Omnimount; then
        return 0
    fi
    open "$OMNIMOUNT_APP" || warn "Could not open Omnimount automatically; open $OMNIMOUNT_APP manually"
}

omnimount_build_from_source() {
    local brew_prefix="$1"
    local build_arch="" work_dir="" log=""
    local -a statuses=()

    omnimount_require_build_tools || return 1
    omnimount_refuse_if_running || return 1
    build_arch="$(omnimount_arch)"
    log="$(omnimount_state_dir)/build.log"
    mkdir -p -- "$(omnimount_state_dir)" || return 1
    work_dir="$(mktemp -d "${TMPDIR:-/tmp}/omnimount.XXXXXX")" || {
        error "Could not create a temporary directory for Omnimount"
        return 1
    }

    info "Building Omnimount ${OMNIMOUNT_VERSION} for ${build_arch} with FUSE-T (log: ${log})"
    # Not `if ! build | tee`: that form disables set -e for the whole build,
    # so a failed step would fall through and the function could return 0.
    set +e
    omnimount_run_build "$work_dir" "$brew_prefix" "$build_arch" 2>&1 | tee "$log"
    statuses=("${PIPESTATUS[@]}")
    set -e
    if ((${statuses[0]:-1} != 0 || ${statuses[1]:-1} != 0)); then
        error "Omnimount source build failed. Last lines of ${log}:"
        tail -n 40 -- "$log" >&2 || true
        return 1
    fi

    omnimount_write_stamp || {
        error "Omnimount built, but the install stamp could not be written"
        return 1
    }
    omnimount_warn_if_adhoc "$brew_prefix/bin/omnimount"
    success "Omnimount ${OMNIMOUNT_VERSION} installed"
    "$brew_prefix/bin/omnimount" doctor || warn "Omnimount doctor reported an issue; finish the permissions below, then run: omnimount doctor"
    omnimount_restart_helper
    omnimount_open_app
}

omnimount_require_fuse_t() {
    if omnimount_fuse_t_ready; then
        return 0
    fi
    if ! macos_fuse_t_cask_installed; then
        warn "FUSE-T is not installed; rerun ./bootstrap.sh to install the Brewfile first"
    else
        warn "FUSE-T is listed by Homebrew but ${FUSE_T_LIB} is missing; reinstall the fuse-t cask"
    fi
    return 1
}

install_omnimount() {
    local brew_prefix=""

    macos_brew_prefix || {
        warn "Homebrew is required to install Omnimount"
        return 1
    }
    brew_prefix="$MACOS_BREW_PREFIX"
    omnimount_require_fuse_t || return 1
    if macos_macfuse_present; then
        error "macFUSE is installed. Remove it before using FUSE-T; the two conflict."
        return 1
    fi

    if omnimount_app_notarized; then
        if [[ "${OMNIMOUNT_REBUILD:-0}" == "1" ]]; then
            info "Notarized Omnimount is installed; relinking its CLI instead of building from source"
        fi
        omnimount_link_notarized "$brew_prefix"
        return
    fi

    omnimount_build_from_source "$brew_prefix"
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
    set_xdg_environment_defaults

    info "Omnimount (ext2/3/4 and NTFS disks)"

    # Fill the brew prefix cache here, in the parent shell; offered actions run
    # in subshells. Brew may be absent, which the steps below handle.
    macos_brew_prefix || true

    offer_if_missing "Install or repair Omnimount for ext2/3/4 and NTFS disks?" omnimount_installed install_omnimount "Omnimount already installed"

    if [[ -d "$OMNIMOUNT_APP" ]]; then
        omnimount_setup_notes
    fi
}

main "$@"
