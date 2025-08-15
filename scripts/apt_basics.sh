# shellcheck shell=bash
install_apt_basics() {
  log "Installing base apt packages…"
  apt_update_once
  apt_install "${APT_PKGS[@]}"
}

register_installer install_apt_basics 10