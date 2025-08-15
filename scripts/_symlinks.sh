# shellcheck shell=bash
_same_link() { [ -L "$2" ] && [ "$(readlink -f "$2")" = "$(readlink -f "$1")" ]; }

symlink_dotfiles() {
  log "Symlinking dotfiles…"
  ensure_dir "${HOME}/.config"
  link() {
    local src="$1" dst="$2"
    ensure_dir "$(dirname "$dst")"
    if ! _same_link "$src" "$dst"; then
      rm -f "$dst"
      ln -sfn "$src" "$dst"
      log "→ $dst → $src"
    fi
  }
  for f in .gitconfig .zshrc .p10k.zsh .profile; do
    [ -f "${REPO_DIR}/home/${f}" ] && link "${REPO_DIR}/home/${f}" "${HOME}/${f}"
  done
  if [ -d "${REPO_DIR}/home/.config" ]; then
    shopt -s dotglob
    for item in "${REPO_DIR}/home/.config"/*; do
      [ -e "$item" ] || continue
      link "$item" "${HOME}/.config/$(basename "$item")"
    done
    shopt -u dotglob
  fi
}

register_installer symlink_dotfiles 20