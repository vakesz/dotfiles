#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Backup existing dotfiles
backup_dotfiles() {
    log "Backing up existing dotfiles"
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    for file in .gitconfig .zshrc; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_DIR/"
            log "Backed up $file to $BACKUP_DIR"
        fi
    done
}

log "Starting dotfiles setup"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please do not run this script as root"
    exit 1
fi

# Backup existing dotfiles
backup_dotfiles

log "Updating and upgrading packages"
sudo apt update && sudo apt upgrade -y

log "Installing essential packages"
sudo apt install -y \
  git \
  neovim \
  python3 \
  python3-pip \
  python3-venv \
  build-essential \
  mc \
  zsh \
  curl \
  wget \
  htop \
  tree \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release \
  clang \
  gdb \
  cmake \
  jq \
  unzip \
  zip \
  ripgrep \
  fd-find \
  bat \
  fzf

# Create necessary directories
log "Creating necessary directories"
mkdir -p "$HOME"/bin
mkdir -p "$HOME"/.local/bin

# Install Docker
log "Installing Docker"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker "$USER"
    log "Docker installed (logout/login required for group membership)"
else
    log "Docker already installed"
fi

# Install Node.js via NodeSource
log "Installing Node.js"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    log "Node.js installed"
else
    log "Node.js already installed"
fi

# Install Delta (better git diff)
echo "Installing Delta for better git diffs"
if ! command -v delta &> /dev/null; then
  DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r .tag_name | tr -d 'v')
  wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
  sudo dpkg -i git-delta_"${DELTA_VERSION}"_amd64.deb
  rm git-delta_"${DELTA_VERSION}"_amd64.deb
  echo "Delta installed"
else
  echo "Delta already installed"
fi

# Install JetBrains Mono Nerd Font
echo "Installing JetBrains Mono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
FONT_NAME="JetBrainsMono"
if [ ! -f "$FONT_DIR/${FONT_NAME}.zip" ] && [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
  mkdir -p "$FONT_DIR"
  cd "$FONT_DIR"
  wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
  unzip -q "${FONT_NAME}.zip" -d "${FONT_NAME}/"
  rm "${FONT_NAME}.zip"
  fc-cache -fv
  echo "JetBrains Mono Nerd Font installed"
  cd - > /dev/null
else
  echo "JetBrains Mono Nerd Font already installed"
fi

# Install Oh My Zsh and plugins
log "Setting up ZSH with Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Oh My Zsh installed"
else
    log "Oh My Zsh already installed"
fi

# Install additional ZSH plugins
log "Installing ZSH plugins"

# Install zsh-autosuggestions
ZSH_AUTOSUGGESTIONS_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
    log "zsh-autosuggestions installed"
else
    log "zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
ZSH_SYNTAX_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
if [ ! -d "$ZSH_SYNTAX_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_DIR"
    log "zsh-syntax-highlighting installed"
else
    log "zsh-syntax-highlighting already installed"
fi

# Install fast-syntax-highlighting (better performance)
ZSH_FAST_SYNTAX_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
if [ ! -d "$ZSH_FAST_SYNTAX_DIR" ]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_FAST_SYNTAX_DIR"
    log "fast-syntax-highlighting installed"
else
    log "fast-syntax-highlighting already installed"
fi

# Install zsh-completions
ZSH_COMPLETIONS_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
if [ ! -d "$ZSH_COMPLETIONS_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_COMPLETIONS_DIR"
    log "zsh-completions installed"
else
    log "zsh-completions already installed"
fi

# Copying dotfiles
log "Copying dotfiles"
cp .gitconfig ~/.gitconfig
cp .zshrc ~/.zshrc

# Create bin directory and copy scripts
if [ ! -d "$HOME/bin" ]; then
  mkdir -p "$HOME/bin"
  echo "Created ~/bin directory"
else
  echo "$HOME/bin directory already exists"
fi

# Copy bin scripts and make them executable
if [ -d "bin" ]; then
  cp bin/* "$HOME/bin/"
  chmod +x "$HOME/bin/"*
  echo "Copied custom scripts to ~/bin and made them executable"
fi

# Setting Zsh as default shell
log "Setting Zsh as default shell"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    log "Default shell changed to Zsh"
else
    log "Zsh is already the default shell"
fi

# Set up Git safe directory (for WSL2)
if grep -q microsoft /proc/version 2>/dev/null; then
    log "Detected WSL2, configuring Git safe directories"
    git config --global --add safe.directory '*'
fi

# Final message
log "Setup complete!"
echo ""
echo -e "${GREEN}Dotfiles have been successfully set up!${NC}"
echo -e "${YELLOW}Note:${NC} Please log out and log back in for all changes to take effect."
echo -e "${YELLOW}Docker users:${NC} You may need to logout/login for Docker group membership to take effect."
echo ""

