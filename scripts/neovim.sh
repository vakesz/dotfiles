# shellcheck shell=bash
install_neovim() {
  # Upgrade if not latest
  local arch latest_release url tmp_tar installed_version

  # Determine latest stable release tag
  latest_release="$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases" \
    | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n1)"
  if [ -z "$latest_release" ]; then
    error "Could not determine latest Neovim release"
    return 1
  fi

  # If Neovim already installed, compare versions (using need_cmd helper)
  if need_cmd nvim; then
    installed_version="$(nvim --version 2>/dev/null | head -n1 | awk '{print $2}')" # e.g. v0.10.1
    if [ "$installed_version" = "$latest_release" ]; then
      log "Neovim already latest ($installed_version)"
      return 0
    else
      log "Upgrading Neovim $installed_version -> $latest_release"
    fi
  else
    log "Installing Neovim $latest_release..."
  fi

  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64) arch="arm64" ;;
    *) error "Unsupported arch for Neovim"; return 1 ;;
  esac

  url="https://github.com/neovim/neovim/releases/download/${latest_release}/nvim-linux-${arch}.tar.gz"
  tmp_tar="$(mktemp --suffix .tar.gz)"
  if curl -fsSL "$url" -o "$tmp_tar"; then
    ensure_dir /opt
    sudo tar -xzf "$tmp_tar" -C /opt/
    sudo ln -sf "/opt/nvim-linux-${arch}/bin/nvim" /usr/local/bin/nvim
  else
    error "Failed to download Neovim archive"
    rm -f "$tmp_tar"
    return 1
  fi
  rm -f "$tmp_tar"
}

register_installer install_neovim 140