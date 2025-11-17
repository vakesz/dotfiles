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

    log_success "Tooling bootstrap complete!"
}

main "$@"
