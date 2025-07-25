#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# setup-dotfiles.sh
#
# Description:
#   Bootstraps a Debian/Ubuntu system with essential packages, tools, and
#   user environment customizations.
#
# Features:
#   - Installs core development packages and utilities
#   - Sets up Docker Engine and adds user to docker group
#   - Installs Node.js LTS and common global npm tools
#   - Installs JetBrains Mono Nerd Font for terminal and editor use
#   - Installs and configures Oh My Zsh with zplug plugin manager
#   - Installs Git delta for improved diff output and LazyGit for TUI Git
#   - Copies user dotfiles (.gitconfig, .zshrc) into home directory
#   - Configures Zsh history rotation via cron
#   - Applies locale fixes for WSL2 if detected
#
# Usage:
#   start.sh [ -h | --help ]
#
# Preconditions:
#   - You must have sudo privileges (will prompt for passwords)
#   - Do NOT run this script as root (it performs user-level actions)
#
# Exit codes:
#   0   Success
#   >0  Error occurred; check output for details
# ----------------------------------------------------------------------------

# Exit immediately on unhandled errors, treat unset variables as errors,
# and propagate errors through pipes.
set -Eeo pipefail
# IFS: split on newline and tab only (protects spaces in file names)
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Color codes for log output
# -----------------------------------------------------------------------------
readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly NC="\033[0m"   # No Color / reset

# -----------------------------------------------------------------------------
# Logging functions
#   log:   Informational messages
#   warn:  Warnings
#   error: Error + exit
# -----------------------------------------------------------------------------
log()   { printf "%b[%s] %s%b\n" "$GREEN" "$(date +'%F %T')" "$1" "$NC"; }
warn()  { printf "%b[%s] WARNING: %s%b\n" "$YELLOW" "$(date +'%F %T')" "$1" "$NC"; }
error() { printf "%b[%s] ERROR: %s%b\n" "$RED" "$(date +'%F %T')" "$1" "$NC"; exit 1; }

# -----------------------------------------------------------------------------
# show_help: Display usage information and exit
# -----------------------------------------------------------------------------
show_help() {
  cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h|--help]

Options:
  -h, --help    Show this help message and exit

Preconditions:
  - sudo privileges
  - do NOT run as root
EOF
}

# Parse flags
case "${1:-}" in
  -h|--help) show_help; exit 0 ;;
  -*) error "Unknown option: $1" ;;
esac

# Directory of this script, used to locate dotfiles for copying
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------------------------------------------
# detect_os: Verify running on Ubuntu or Debian and set OS variable
# -----------------------------------------------------------------------------
detect_os() {
  [[ -r /etc/os-release ]] || error "Cannot detect OS: missing /etc/os-release"
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ $ID =~ ^(ubuntu|debian)$ ]] || error "Unsupported OS: $ID"
  OS=$ID
  log "Detected OS: $PRETTY_NAME"
}

# -----------------------------------------------------------------------------
# install_packages: Update apt cache and install essential packages
# -----------------------------------------------------------------------------
install_packages() {
  log "Updating apt cache and upgrading existing packages"
  sudo apt update && sudo apt upgrade -y

  log "Installing core development packages and utilities"
  local pkgs=(
    git neovim python3-pip python3-venv build-essential mc zsh curl wget
    htop tree software-properties-common apt-transport-https
    ca-certificates gnupg lsb-release clang gdb cmake jq unzip
    zip libarchive-tools ruby-full zlib1g-dev gnupg scdaemon
  )
  sudo apt install -y "${pkgs[@]}"
}

# -----------------------------------------------------------------------------
# install_tools: Install Git delta and LazyGit from GitHub releases if missing
# -----------------------------------------------------------------------------
install_tools() {
  if ! command -v delta &>/dev/null; then
    log "Installing git-delta for enhanced diffs"
    VER=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest \
      | grep -Po '"tag_name": "\K[^"]+')
    URL="https://github.com/dandavison/delta/releases/download/${VER}/git-delta_${VER}_amd64.deb"
    tmp=$(mktemp --suffix .deb)
    curl -fsSL "$URL" -o "$tmp"
    sudo dpkg -i "$tmp" || sudo apt install -f -y
    rm -f "$tmp"
  else
    log "git-delta already installed"
  fi

  if ! command -v colorls &>/dev/null; then
    log "Installing colorls Ruby gem"
    sudo gem install colorls
  else
    log "colorls already installed"
  fi

if ! command -v hugo &>/dev/null; then
  log "Installing Hugo static site generator..."

  latest_release=$(curl -fsSL https://api.github.com/repos/gohugoio/hugo/releases/latest)
  hugo_tag=$(grep -Po '"tag_name": "\K[^"]+' <<< "$latest_release")
  hugo_ver="${hugo_tag#v}"

  url="https://github.com/gohugoio/hugo/releases/download/${hugo_tag}/hugo_extended_${hugo_ver}_linux-amd64.deb"
  tmp_deb=$(mktemp --suffix .deb)

  curl -fsSL "$url" -o "$tmp_deb" &&
  sudo dpkg -i "$tmp_deb" ||
  sudo apt install -f -y

  rm -f "$tmp_deb"
else
  log "Hugo already installed"
fi
}

# -----------------------------------------------------------------------------
# install_docker: Add Docker repository, install Docker Engine, and add user to docker group
# -----------------------------------------------------------------------------
install_docker() {
  if command -v docker &>/dev/null; then
    log "Docker already installed, skipping"
    return
  fi

  log "Setting up Docker repository and GPG key"
  curl -fsSL https://download.docker.com/linux/"$OS"/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/$OS $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "Installing Docker Engine and related components"
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  log "Adding user '$USER' to docker group"
  sudo usermod -aG docker "$USER"
  log "User '$USER' added to docker group. Please re-login or run 'newgrp docker'"
}

# -----------------------------------------------------------------------------
# install_node: Set up Node.js LTS and install common global npm tools
# -----------------------------------------------------------------------------
install_node() {
  if ! command -v node &>/dev/null; then
    log "Installing Node.js LTS via Nodesource"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs

    log "Installing global npm tools: tailwindcss, postcss, autoprefixer, eslint"
    sudo npm install -g tailwindcss postcss autoprefixer eslint
  else
    log "Node.js already installed"
  fi
}

# -----------------------------------------------------------------------------
# install_font: Download and install JetBrains Mono Nerd Font
# -----------------------------------------------------------------------------
install_font() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  if [[ -d $font_dir ]]; then
    log "JetBrains Mono Nerd Font already present"
    return
  fi

  log "Downloading and installing JetBrains Mono Nerd Font"
  mkdir -p "$font_dir"
  tmp=$(mktemp --suffix .zip)
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o "$tmp"
  unzip "$tmp" -d "$font_dir"
  rm -f "$tmp"
  fc-cache -fv  # Rebuild font cache
}

# -----------------------------------------------------------------------------
# install_oh_my_zsh: Install Oh My Zsh if missing
# -----------------------------------------------------------------------------
install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended
  else
    log "Oh My Zsh already installed"
  fi
}

# -----------------------------------------------------------------------------
# setup_zsh: Ensure Zsh, Oh My Zsh, zplug, and history rotation
# -----------------------------------------------------------------------------
setup_zsh() {
  if ! command -v zsh &>/dev/null; then
    log "Installing Zsh shell"
    sudo apt install -y zsh
  fi

  install_oh_my_zsh

  if [[ ! -d "$HOME/.zplug" ]]; then
    log "Cloning zplug for Zsh plugin management"
    git clone https://github.com/zplug/zplug "$HOME/.zplug"
  else
    log "zplug already installed"
  fi

  if ! crontab -l 2>/dev/null | grep -q "history.*gzip"; then
    log "Scheduling weekly Zsh history rotation and compression"
    (crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/bin/find \$HOME/.local/state/zsh -name 'history-*' -mtime +30 -exec gzip {} \\;") | crontab -
  else
    log "Zsh history rotation cron job already configured"
  fi
}

# -----------------------------------------------------------------------------
# copy_dotfiles: Securely copy .gitconfig and .zshrc from script directory to home
# -----------------------------------------------------------------------------
copy_dotfiles() {
  log "Copying dotfiles (.gitconfig, .zshrc) to home directory"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/gems"
  cp "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
  cp "$SCRIPT_DIR/.config/.p10k.zsh" "$HOME/.config/.p10k.zsh"
  cp "$SCRIPT_DIR/.zshrc"      "$HOME/.zshrc"
}

# -----------------------------------------------------------------------------
# finalize: Change default shell, apply WSL2 locale fixes, and finish
# -----------------------------------------------------------------------------
finalize() {
  if [[ $SHELL != "$(command -v zsh)" ]]; then
    chsh -s "$(command -v zsh)"
    log "Default shell changed to zsh"
  fi

  # On WSL2, ensure locale is properly generated and set to UTF-8
  if grep -qi microsoft /proc/version 2>/dev/null; then
    log "Applying WSL2 locale configuration"
    grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen || \
      echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen
    sudo locale-gen
    sudo tee /etc/default/locale <<< 'LANG=en_US.UTF-8'
  fi

  log "Cleaning up apt caches and removing unnecessary packages"
  sudo apt autoremove -y
  sudo apt autoclean

  log "Bootstrap complete! Please log out and log back in to activate changes."
}

# -----------------------------------------------------------------------------
# main: Entry point - validate, detect OS, and run all setup steps
# -----------------------------------------------------------------------------
main() {
  # Prevent running as root; user-level operations required
  [[ $EUID -eq 0 ]] && error "Do not run this script as root"

  detect_os
  install_packages
  install_tools
  install_docker
  install_node
  install_font
  setup_zsh
  copy_dotfiles
  finalize
}

# Invoke main with all script arguments
main "$@"
