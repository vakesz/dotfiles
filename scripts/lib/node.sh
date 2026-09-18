#!/usr/bin/env bash
# Install and expose the fnm-managed Node.js and Corepack toolchain.

# shellcheck source=scripts/lib/ui.sh
source "${BASH_SOURCE[0]%/*}/ui.sh"
# shellcheck source=scripts/lib/paths.sh
source "${BASH_SOURCE[0]%/*}/paths.sh"

load_fnm_environment() {
    set_xdg_environment_defaults

    export FNM_DIR="${FNM_DIR:-$XDG_DATA_HOME/fnm}"
    export PNPM_HOME="${PNPM_HOME:-$XDG_DATA_HOME/pnpm}"

    case ":$PATH:" in
        *":$PNPM_HOME/bin:"*) ;;
        *) export PATH="$PNPM_HOME/bin:$PATH" ;;
    esac

    command -v fnm >/dev/null 2>&1 || return 1
    eval "$(fnm env --shell bash --corepack-enabled)"
}

fnm_managed_node_available() {
    load_fnm_environment || return 1

    local node_path="" corepack_path=""
    node_path="$(command -v node 2>/dev/null)" || return 1
    corepack_path="$(command -v corepack 2>/dev/null)" || return 1

    [[ -n "${FNM_MULTISHELL_PATH:-}" ]] || return 1
    [[ "$node_path" == "$FNM_MULTISHELL_PATH/"* ]] || return 1
    [[ "$corepack_path" == "$FNM_MULTISHELL_PATH/"* ]]
}

install_node_with_fnm() {
    load_fnm_environment || {
        warn "fnm not available; skipping Node.js setup"
        return 0
    }

    info "Installing latest Node.js LTS with fnm..."
    fnm install --lts --corepack-enabled --use

    local node_version=""
    node_version="$(node --version)"
    fnm default "$node_version"
    success "Node.js $node_version installed and selected with fnm"
}

pnpm_enabled() {
    # Puts PNPM_HOME on PATH even when fnm itself is missing, which is how a
    # corepack-enabled pnpm is found.
    load_fnm_environment >/dev/null 2>&1 || true
    command -v pnpm >/dev/null 2>&1
}

enable_pnpm_with_corepack() {
    fnm_managed_node_available || {
        warn "No fnm-managed Node.js runtime available; skipping pnpm setup"
        return 0
    }

    info "Enabling pnpm via corepack..."
    corepack enable pnpm
    success "pnpm enabled"
}

offer_node_toolchain_setup() {
    require_command fnm "Node.js and pnpm setup" || return 0

    offer_if_missing "Install latest Node.js LTS with fnm?" \
        fnm_managed_node_available install_node_with_fnm \
        "fnm-managed Node.js already available"

    offer_if_missing "Enable pnpm via corepack?" \
        pnpm_enabled enable_pnpm_with_corepack \
        "pnpm already available"
}
