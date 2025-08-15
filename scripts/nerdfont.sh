# shellcheck shell=bash
install_nerd_font() {
  log "Installing Nerd Font (${FONT_NAME})…"
  local font_dir="${HOME}/.local/share/fonts"
  ensure_dir "$font_dir"
  if find "$font_dir" -maxdepth 1 -type f -name "${FONT_NAME}*.ttf" | grep -q .; then
    log "Nerd Font (${FONT_NAME}) already present. Skipping."
    return
  fi
  local tmp_zip
  tmp_zip="$(mktemp)"
  curl -fsSL "$NERD_FONT_URL" -o "$tmp_zip"
  unzip -oq "$tmp_zip" -d "$font_dir"
  rm -f "$tmp_zip"
  fc-cache -f >/dev/null 2>&1 || true
  log "Nerd Font installed to ${font_dir}"
}

register_installer install_nerd_font 30