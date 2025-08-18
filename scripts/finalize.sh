# shellcheck shell=bash
finalize() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [ "${SHELL:-}" != "$zsh_path" ]; then
    if chsh -s "$zsh_path"; then
      log "Default shell changed to zsh."
    else
      warn "Couldn't change default shell. Try: sudo chsh -s \"$zsh_path\" \"$USER\""
    fi
  fi

  if is_wsl2; then
    log "Applying WSL2 locale configuration"
    if ! locale -a 2>/dev/null | grep -q "en_US.utf8"; then
      grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen || \
        echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
      sudo locale-gen
    fi
    if ! grep -qxF 'LANG=en_US.UTF-8' /etc/default/locale 2>/dev/null; then
      echo 'LANG=en_US.UTF-8' | sudo tee /etc/default/locale >/dev/null
    fi
  fi

  # Disable telemetry packages
  log "Disabling telemetry packages (ubuntu-report, popularity-contest)"
  if dpkg -s ubuntu-report >/dev/null 2>&1 || dpkg -s popularity-contest >/dev/null 2>&1; then
    sudo apt purge -y ubuntu-report popularity-contest || true
  fi

  log "Cleaning up apt caches and removing unnecessary packages"
  sudo apt autoremove -y
  sudo apt autoclean -y || true
  sudo apt-get clean -y || true
}

register_installer finalize 1000