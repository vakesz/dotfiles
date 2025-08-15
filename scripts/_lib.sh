# shellcheck shell=bash
DISTRO=""
FONT_NAME="JetBrainsMono"
# shellcheck disable=SC2034
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

# Track whether we changed APT sources; if yes, do a single update before install
UPDATED_APT=0

# shellcheck disable=SC2034
APT_PKGS=(
  # essentials
  git curl wget unzip zip tar ca-certificates gnupg lsb-release software-properties-common apt-transport-https
  # shells & utils
  zsh lsd fzf mc tldr tig httpie nmap tree htop jq ripgrep fd-find
  # compilers & build
  build-essential gcc g++ clang llvm cmake make ninja-build pkg-config autoconf automake
  # scripting / langs
  python3 python3-pip python3-venv pipx lua5.4
  # java
  openjdk-21-jdk
  # format/lint
  shellcheck clang-format
  # fonts cache for Nerd Fonts
  fontconfig
)

# npm globals
# shellcheck disable=SC2034
NPM_GLOBALS=(prettier eslint)

# pipx tools
# shellcheck disable=SC2034
PIPX_TOOLS=(pre-commit black ruff pytest)

# cargo tools
# shellcheck disable=SC2034
CARGO_TOOLS=(topgrade)

log()   { printf "\033[1;34m[dotfiles]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[dotfiles]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[dotfiles]\033[0m %s\n" "$*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

require_sudo() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
      error "sudo is required when not running as root."; exit 1
    fi
    sudo -v || { error "This script needs sudo privileges."; exit 1; }
  fi
}

detect_distro() {
  if [ -r /etc/os-release ]; then
# shellcheck disable=SC1091
    . /etc/os-release
    DISTRO="${ID:-}"
  fi
  case "${DISTRO}" in
    ubuntu|debian) ;;
    *) error "Unsupported distro: ${DISTRO:-unknown}"; exit 1 ;;
  esac
  log "Detected distro: $DISTRO"
}

apt_update_once() {
  sudo apt-get update -y
}

apt_update_if_needed() {
  if [ "$UPDATED_APT" -eq 1 ]; then
    sudo apt-get update -y
    UPDATED_APT=0
  fi
}

apt_install() {
  sudo apt-get install -y --no-install-recommends "$@"
}

ensure_dir() {
  mkdir -p "$1"
}

ensure_cmd_pkg() { need_cmd "$1" || apt_install "$2"; }

add_apt_source() {
  # $1=name, $2=list_line, $3=key_path (optional), $4=key_url (optional)
  local name="$1" list="$2" key_path="${3:-}" key_url="${4:-}"
  if [ -n "$key_url" ] && [ ! -s "$key_path" ]; then
    sudo install -m 0755 -d "$(dirname "$key_path")"
    curl -fsSL "$key_url" | sudo gpg --dearmor -o "$key_path"
    sudo chmod a+r "$key_path" || true
  fi
  local list_file="/etc/apt/sources.list.d/${name}.list"
  if [ ! -f "$list_file" ] || ! grep -qxF "$list" "$list_file"; then
    echo "$list" | sudo tee "$list_file" >/dev/null
    UPDATED_APT=1
  fi
}

is_wsl() {
  grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

is_wsl2() {
  if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    grep -qiE 'WSL2|microsoft-standard-WSL2' /proc/sys/kernel/osrelease 2>/dev/null
  else
    return 1
  fi
}

INSTALLERS=()

register_installer() {
  local fn="$1"
  local order="${2:-50}"
  INSTALLERS+=("$order:$fn")
}

run_installers() {
  local entry fn
  mapfile -t sorted < <(printf '%s\n' "${INSTALLERS[@]}" | sort -n)
  for entry in "${sorted[@]}"; do
    fn="${entry#*:}"
    "$fn"
  done
}

main() {
  require_sudo
  detect_distro
  run_installers
  log "All done! Reboot or log out/in to pick up shell & group changes."
}