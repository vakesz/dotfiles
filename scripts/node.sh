# shellcheck shell=bash
ensure_npm_user_prefix() {
  local current
  current="$(npm config get prefix 2>/dev/null || true)"
  if [ "$current" = "/usr" ] || [ "$current" = "/usr/local" ] || [ -z "$current" ]; then
    mkdir -p "$HOME/.local"
    npm config set prefix "$HOME/.local"
    log "Configured npm global prefix → $HOME/.local"
  fi
}

install_node() {
  if ! need_cmd node; then
    local node_key="/etc/apt/keyrings/nodesource.gpg"
    local node_list
    node_list="deb [signed-by=${node_key}] https://deb.nodesource.com/node_22.x $(lsb_release -cs) main"
    add_apt_source "nodesource" "$node_list" "$node_key" "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key"
    apt_update_if_needed
    apt_install nodejs
  else
    log "Node $(node -v) already installed."
  fi
  ensure_npm_user_prefix
  export PATH="$HOME/.local/bin:$PATH"
  if ! need_cmd corepack; then npm i -g corepack || true; fi
  # Try to enable corepack; if system dir not writable, use user bin dir.
  if need_cmd corepack; then
    corepack_dir="$(dirname "$(command -v corepack)")"
    if [ ! -w "$corepack_dir" ]; then
      mkdir -p "$HOME/.local/bin"
      corepack enable --install-directory "$HOME/.local/bin" || true
    else
      corepack enable || true
    fi
  fi
  # Prepare pnpm; if that fails (e.g. due to permissions), fall back to installing pnpm directly.
  corepack prepare pnpm@latest --activate || npm install -g pnpm || true
  for pkg in "${NPM_GLOBALS[@]}"; do
    if ! npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
      npm i -g "$pkg"
    fi
  done
}

register_installer install_node 50