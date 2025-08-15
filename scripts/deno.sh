# shellcheck shell=bash
install_deno() {
  if need_cmd deno; then
    log "Upgrading Deno to latest…"
    deno upgrade || true
  else
    log "Installing Deno via official APT repository…"
    local deno_key="/etc/apt/keyrings/deno.gpg"
    local deno_list="deb [signed-by=${deno_key}] https://dl.deno.land/apt stable main"
    add_apt_source "deno" "$deno_list" "$deno_key" "https://dl.deno.land/deno.asc"
    apt_update_if_needed
    apt_install deno
  fi
  log "Deno version: $(deno --version 2>/dev/null | head -n1 || echo 'installed')"
}

register_installer install_deno 100