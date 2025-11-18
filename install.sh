#!/usr/bin/env bash
#
# Bootstrapper for the dotfiles tooling stack.
# Delegates to platform and tooling helpers for a maintainable install flow.
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
PACKAGES_JSON="$SCRIPTS_DIR/packages.json"

if [[ ! -f "$PACKAGES_JSON" ]]; then
    echo "packages.json is missing from scripts/ - cannot continue"
    exit 1
fi

source "$SCRIPTS_DIR/common.sh"
source "$SCRIPTS_DIR/platform-helpers.sh"
source "$SCRIPTS_DIR/tooling/install_ohmyposh.sh"
source "$SCRIPTS_DIR/tooling/install_cargo.sh"
source "$SCRIPTS_DIR/tooling/install_npm.sh"
source "$SCRIPTS_DIR/tooling/install_pip.sh"
source "$SCRIPTS_DIR/tooling/install_go.sh"
source "$SCRIPTS_DIR/tooling/install_deno.sh"

apply_stow_symlinks() {
    set_log_context "stow"
    if ! command_exists stow; then
        log_warning "GNU Stow not installed; skipping symlink application"
        clear_log_context
        return 0
    fi

    log_info "Applying dotfiles via GNU Stow..."

    # Ensure we run from DOTFILES_DIR
    pushd "$DOTFILES_DIR" >/dev/null || die "Cannot change to $DOTFILES_DIR"

    # Apply stow from the repo root. .stow-local-ignore in the repo controls what is
    # excluded, so a single `stow .` is sufficient for typical dotfiles repositories.
    log_info "Applying stow from repository root (stow .) — .stow-local-ignore will control exclusions"
    declare -a stow_args=("-v" "--restow" "--target=$HOME")
    # Optionally allow a dry-run/simulate mode via env var
    if [[ "${DOTFILES_STOW_SIMULATE-}" == "1" || "${DOTFILES_STOW_SIMULATE-}" == "true" ]]; then
        stow_args=("-n" "${stow_args[@]}")
    fi
    if stow "${stow_args[@]}" .; then
        log_success "Stow completed successfully"
    else
        log_error "Stow encountered issues (see output above)"
    fi

    popd >/dev/null || true
    clear_log_context
}

main() {
    log_info "Starting tooling bootstrap..."

    detect_platform
    ensure_package_manager

    install_core_packages
    install_ohmyposh

    install_rust_tooling
    install_npm_tooling
    install_pip_tooling
    install_go_tooling
    install_deno_runtime

    apply_platform_tweaks

    # Apply dotfile symlinks using GNU Stow if it's available.
    # We build a list of package directories from the repository root and
    # honor .stow-local-ignore for top-level exclusions.
    apply_stow_symlinks

    log_success "Tooling bootstrap complete!"
}

main "$@"
 
