# shellcheck shell=bash
install_zig() {
  local platform version url tmp index_json

  ensure_cmd_pkg jq jq
  ensure_cmd_pkg curl curl

  case "$(dpkg --print-architecture)" in
    amd64)  platform="x86_64-linux" ;;
    arm64)  platform="aarch64-linux" ;;
    *) error "Unsupported arch for Zig"; return 1 ;;
  esac

  index_json="$(curl -fsSL https://ziglang.org/download/index.json)"
  if [ -z "$index_json" ]; then
    error "Could not fetch Zig index"; return 1
  fi

  version="$(printf '%s' "$index_json" | jq -r 'keys[]' | grep -E '^[0-9]+\.[0-9]+' | sort -Vr | head -n1)"
  if [ -z "$version" ] || [ "$version" = "null" ]; then
    error "Could not determine latest Zig stable version"; return 1
  fi

  url="$(printf '%s' "$index_json" | jq -r --arg v "$version" --arg p "$platform" '.[$v][$p].tarball // empty')"
  if [ -z "$url" ]; then
    error "No Zig tarball for platform ${platform} in version ${version}"; return 1
  fi

  if need_cmd zig && [ "$(zig version 2>/dev/null)" = "$version" ]; then
    log "Zig ${version} already installed."
    return 0
  fi

  tmp="$(mktemp -d)"
  log "Installing Zig ${version} (${platform})…"
  if ! curl -fL "$url" -o "${tmp}/zig.tar.xz"; then
    rm -rf "$tmp"
    error "Failed to download Zig from ${url}"; return 1
  fi
  sudo rm -rf /opt/zig
  sudo mkdir -p /opt/zig
  sudo tar -C /opt/zig -xJf "${tmp}/zig.tar.xz" --strip-components=1
  rm -rf "$tmp"

  sudo ln -sf /opt/zig/zig /usr/local/bin/zig
  log "Installed Zig: $(/usr/local/bin/zig version 2>/dev/null || echo 'ok')"
}

register_installer install_zig 90