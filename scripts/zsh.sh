# shellcheck shell=bash
install_oh_my_zsh() { install_ohmyzsh; }

install_ohmyzsh() {
  if [ -d "${HOME}/.oh-my-zsh" ]; then
    log "Oh My Zsh already present. Skipping."
  else
    log "Installing Oh My Zsh…"
    RUNZSH="no" KEEP_ZSHRC="yes" CHSH="no" sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

setup_zsh() {
  ensure_cmd_pkg zsh zsh
  install_ohmyzsh

  if [ ! -d "$HOME/.zplug" ]; then
    log "Cloning zplug (Zsh plugin manager)…"
    git clone https://github.com/zplug/zplug "$HOME/.zplug"
  fi

  # Schedule weekly Zsh history rotation & compression (keeps >30d gzipped)
  if ! crontab -l 2>/dev/null | grep -q "history.*gzip"; then
    log "Scheduling weekly Zsh history rotation and compression"
    (crontab -l 2>/dev/null; \
      echo "0 3 * * 0 /usr/bin/find \$HOME/.local/state/zsh -name 'history-*' -mtime +30 -exec gzip {} \;") | crontab -
  fi
}

register_installer setup_zsh 40