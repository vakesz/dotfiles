# shellcheck shell=bash
install_deno() {
  if need_cmd deno; then
    log "Upgrading Deno to latest…"
    deno upgrade || true
  else
    log "Installing Deno…"
    local target_user
    target_user="${SUDO_USER:-$USER}"
    # Run the official install script non-interactively (-y) as target (non-root) user when possible.
    if [ "${EUID}" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
      sudo -u "$target_user" bash -c 'curl -fsSL https://deno.land/install.sh | sh -s -- -y' || error "Deno install script failed."
      # Symlink for system-wide availability if binary exists.
      if [ -x "/home/$target_user/.deno/bin/deno" ] && [ ! -e /usr/local/bin/deno ]; then
        ln -sf "/home/$target_user/.deno/bin/deno" /usr/local/bin/deno || true
      fi
    else
      curl -fsSL https://deno.land/install.sh | sh -s -- -y || error "Fallback Deno install script failed."
      if [ -x "$HOME/.deno/bin/deno" ] && [ "$(command -v deno || true)" != "$HOME/.deno/bin/deno" ]; then
        ln -sf "$HOME/.deno/bin/deno" /usr/local/bin/deno 2>/dev/null || true
      fi
    fi
  fi
  log "Deno version: $(deno --version 2>/dev/null | head -n1 || echo 'installed')"
}

register_installer install_deno 100