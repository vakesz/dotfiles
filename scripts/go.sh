# shellcheck shell=bash
install_go() {
  local arch dpkg_arch version tgz url tmp

  ensure_cmd_pkg curl curl

  version="$(curl -fsSL https://go.dev/VERSION?m=text | head -n1)" # e.g., go1.22.6
  if [ -z "$version" ]; then
    error "Could not determine latest Go version"; return 1
  fi

  dpkg_arch="$(dpkg --print-architecture)"
  case "$dpkg_arch" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *) error "Unsupported arch for Go: ${dpkg_arch}"; return 1 ;;
  esac

  tgz="${version}.linux-${arch}.tar.gz"
  url="https://go.dev/dl/${tgz}"

  if need_cmd go && go version 2>/dev/null | grep -q " ${version} "; then
    log "Go ${version} already installed."
    return 0
  fi

  log "Installing Go ${version}…"
  tmp="$(mktemp -d)"
  curl -fL "$url" -o "${tmp}/${tgz}"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "${tmp}/${tgz}"
  rm -rf "$tmp"

  if ! need_cmd go; then
    export PATH="/usr/local/go/bin:${PATH}"
  fi
  log "Installed $(go version)"
}

register_installer install_go 80