# shellcheck shell=bash
install_swift() {
  local tmp swiftly_url arch

  ensure_cmd_pkg curl curl

  # Check if swift is already installed and working
  if need_cmd swift; then
    local current_version
    current_version="$(swift --version 2>/dev/null | head -n1 || echo '')"
    if [ -n "$current_version" ]; then
      log "Swift already installed: $current_version"
      return 0
    fi
  fi

  # Check if swiftly is already installed
  if need_cmd swiftly; then
    log "Swiftly already installed, installing latest Swift..."
    swiftly install latest
    return 0
  fi

  log "Installing Swift using swiftly installer..."
  
  # Determine architecture
  arch="$(uname -m)"
  swiftly_url="https://download.swift.org/swiftly/linux/swiftly-${arch}.tar.gz"
  
  tmp="$(mktemp -d)"
  
  # Download and extract swiftly
  if ! curl -fL "$swiftly_url" -o "${tmp}/swiftly.tar.gz"; then
    rm -rf "$tmp"
    error "Failed to download swiftly from ${swiftly_url}"; return 1
  fi

  # Extract swiftly
  tar -C "$tmp" -xzf "${tmp}/swiftly.tar.gz"
  
  # Run swiftly installer
  if ! "${tmp}/swiftly" init --quiet-shell-followup --assume-yes; then
    rm -rf "$tmp"
    error "Failed to initialize swiftly"; return 1
  fi
  
  rm -rf "$tmp"

  # Source swiftly environment
  local swiftly_env="${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
  if [ -f "$swiftly_env" ]; then
    # shellcheck disable=SC1090
    . "$swiftly_env"
    hash -r
  fi

  # Install latest Swift
  if need_cmd swiftly; then
    swiftly install latest
    log "Installed Swift: $(swift --version 2>/dev/null | head -n1 || echo 'installed')"
  else
    error "Swiftly installation failed"
    return 1
  fi
}

register_installer install_swift 85
