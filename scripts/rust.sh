# shellcheck shell=bash
install_rust() {
  if need_cmd rustup; then
    rustup self update || true
    rustup update || true
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    source "${HOME}/.cargo/env"
  fi
  for crate in "${CARGO_TOOLS[@]}"; do
    if ! cargo install --list 2>/dev/null | grep -q "^${crate} "; then
      cargo install "$crate"
    fi
  done
}

register_installer install_rust 60