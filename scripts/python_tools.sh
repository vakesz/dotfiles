# shellcheck shell=bash
install_python_tools() {
  python3 -m pip install -U pip >/dev/null 2>&1 || true
  apt_install pipx || true
  pipx ensurepath || true
  for tool in "${PIPX_TOOLS[@]}"; do
    pipx install --force "$tool" || true
  done
}

register_installer install_python_tools 70