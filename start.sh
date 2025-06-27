#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# setup-dotfiles.sh
#
# This script bootstraps and configures your Ubuntu/Debian environment with:
#   - Core packages and development tools
#   - Docker
#   - Node.js + npm global tools
#   - JetBrains Mono Nerd Font
#   - Oh My Zsh + plugins
#   - Git delta and LazyGit
#
# Usage:
#   setup-dotfiles.sh [ -h | --help ]
#
# Preconditions:
#   - Sudo privileges
#   - Do NOT run as root
# ----------------------------------------------------------------------------

set -Eeo pipefail
IFS=$'\n\t'

# Color codes for log output
readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly NC="\033[0m"  # No Color

# ----------------------------------------------------------------------------
# Logging functions
# ----------------------------------------------------------------------------
log()   { printf "%b[%s] %s%b\n" "$GREEN" "$(date +'%F %T')" "$1" "$NC"; }
warn()  { printf "%b[%s] WARNING: %s%b\n" "$YELLOW" "$(date +'%F %T')" "$1" "$NC"; }
error() { printf "%b[%s] ERROR: %s%b\n" "$RED" "$(date +'%F %T')" "$1" "$NC"; exit 1; }

# ----------------------------------------------------------------------------
# show_help: Display usage information
# ----------------------------------------------------------------------------
show_help() {
  cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h|--help]

Options:
  -h, --help    Show this message and exit

Preconditions:
  - sudo privileges
  - do NOT run as root
EOF
}

# ----------------------------------------------------------------------------
# Parse command-line flags
# ----------------------------------------------------------------------------
case "${1:-}" in
  -h|--help) show_help; exit 0 ;;
  -*) error "Unknown option: $1" ;;
esac

# Locate script directory for dotfile paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------------------------------
# detect_os: Verify running on Ubuntu or Debian
# ----------------------------------------------------------------------------
detect_os() {
  [[ -r /etc/os-release ]] || error "Cannot detect OS"
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ $ID =~ ^(ubuntu|debian)$ ]] || error "Unsupported OS: $ID"
  OS=$ID
  log "Detected OS: $PRETTY_NAME"
}

# ----------------------------------------------------------------------------
# install_packages: Update apt and install core utilities
# ----------------------------------------------------------------------------
install_packages() {
  log "Updating apt cache and upgrading existing packages"
  sudo apt update && sudo apt upgrade -y

  log "Installing core packages"
  local pkgs=(
    git neovim python3-pip python3-venv build-essential mc zsh curl wget htop tree
    software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    clang gdb cmake jq unzip zip libarchive-tools
  )
  sudo apt install -y "${pkgs[@]}"
}

# ----------------------------------------------------------------------------
# install_tools: Install git-delta (diff pager) & lazygit (terminal UI for git)
# ----------------------------------------------------------------------------
install_tools() {
  # Check and install git-delta
  if command -v delta &>/dev/null; then
    log "git-delta is already installed"
  else
    log "Installing git-delta"
    local VER
    VER=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest \
      | grep -Po '"tag_name": "\K[^"]+')
    local DELTA_URL="https://github.com/dandavison/delta/releases/download/${VER}/git-delta_${VER}_amd64.deb"
    local tmpdelta
    tmpdelta=$(mktemp --suffix .deb)
    curl -fsSL "$DELTA_URL" -o "$tmpdelta"
    sudo dpkg -i "$tmpdelta" || sudo apt install -f -y
    rm -f "$tmpdelta"
  fi

  # Check and install LazyGit
  if command -v lazygit &>/dev/null; then
    log "LazyGit is already installed"
  else
    log "Installing LazyGit"
    local VER
    VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
      | grep -Po '"tag_name": "\K[^"]+')
    local tmpfile
    tmpfile=$(mktemp)
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${VER}/lazygit_${VER#v}_Linux_x86_64.tar.gz" \
      -o "$tmpfile"
    tar -xzf "$tmpfile" lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit "$tmpfile"
  fi
}

# ----------------------------------------------------------------------------
# install_docker: Setup Docker repository and install Docker Engine
# ----------------------------------------------------------------------------
install_docker() {
  if command -v docker &>/dev/null; then
    log "Docker is already installed"
    return
  fi
  log "Installing Docker Engine"
  curl -fsSL https://download.docker.com/linux/"$OS"/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/$OS $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$USER"
  log "Added $USER to docker group; please re-login or run 'newgrp docker'"
}

# ----------------------------------------------------------------------------
# install_node: Install Node.js LTS and global npm packages
# ----------------------------------------------------------------------------
install_node() {
  if command -v node &>/dev/null; then
    log "Node.js is already installed"
    return
  fi
  log "Installing Node.js LTS"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs

  log "Installing global npm packages"
  sudo npm install -g tailwindcss postcss autoprefixer eslint
}

# ----------------------------------------------------------------------------
# install_font: Download and install JetBrains Mono Nerd Font
# ----------------------------------------------------------------------------
install_font() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  if [[ -d $font_dir ]]; then
    log "JetBrains Mono Nerd Font already present"
    return
  fi

  log "Installing JetBrains Mono Nerd Font"
  mkdir -p "$font_dir"
  local tmpzip
  tmpzip=$(mktemp --suffix .zip)
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o "$tmpzip"
  unzip "$tmpzip" -d "$font_dir"
  rm -f "$tmpzip"
  fc-cache -fv
}

# ----------------------------------------------------------------------------
# setup_zsh: Install zplug and configure Zsh with plugins
# ----------------------------------------------------------------------------
setup_zsh() {
  # Check if zsh is installed
  if ! command -v zsh &>/dev/null; then
    log "Zsh not found, installing it first"
    sudo apt install -y zsh
  fi

  # Install zplug if not already installed
  if [[ ! -d "$HOME/.zplug" ]]; then
    log "Installing zplug"
    git clone https://github.com/zplug/zplug "$HOME/.zplug"
  else
    log "zplug is already installed"
  fi
}

# ----------------------------------------------------------------------------
# copy_dotfiles: Copy .gitconfig and .zshrc from script location to home
# ----------------------------------------------------------------------------
copy_dotfiles() {
  log "Copying dotfiles to home directory"
  
  # Create .ssh directory if it doesn't exist to prevent zsh glob errors
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  
  cp "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
  cp "$SCRIPT_DIR/.zshrc"      "$HOME/.zshrc"
}

# ----------------------------------------------------------------------------
# finalize: Change shell to zsh and configure WSL locale if needed
# ----------------------------------------------------------------------------
finalize() {
  # Change default shell to zsh if not already
  if [[ $SHELL != $(command -v zsh) ]]; then
    chsh -s "$(command -v zsh)"
    log "Default shell changed to zsh"
  fi

  # WSL2-specific locale fix
  if grep -qi microsoft /proc/version 2>/dev/null; then
    log "Applying WSL2 locale configuration"
    if ! grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then
      echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen
    fi
    sudo locale-gen
    sudo tee /etc/default/locale <<< 'LANG=en_US.UTF-8'
  fi

  log "Setup complete! Please log out and back in to apply all changes."
}

# ----------------------------------------------------------------------------
# main: Execute all setup steps in order
# ----------------------------------------------------------------------------
main() {
  # Prevent running as root
  [[ $EUID -eq 0 ]] && error "Do not run as root"

  detect_os            # Check OS compatibility
  install_packages     # Core utilities
  install_tools        # git-delta, lazygit
  install_docker       # Docker Engine
  install_node         # Node.js + npm tools
  install_font         # Nerd font
  setup_zsh            # Z shell and plugins
  copy_dotfiles        # Custom dotfiles
  finalize             # Final touches
}

main "$@"
