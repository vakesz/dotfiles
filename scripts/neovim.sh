# shellcheck shell=bash
install_neovim() {
  # TODO: Upgrade if not latest
  if need_cmd nvim; then return; fi
  log "Installing latest stable Neovim..."
  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64) arch="arm64" ;;
    *) error "Unsupported arch for Neovim"; return 1 ;;
  esac
  local latest_release url tmp_tar
  latest_release="$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases" \
    | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n1)"
  url="https://github.com/neovim/neovim/releases/download/${latest_release}/nvim-linux-${arch}.tar.gz"
  tmp_tar="$(mktemp --suffix .tar.gz)"
  if curl -fsSL "$url" -o "$tmp_tar"; then
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