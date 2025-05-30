#!/bin/bash

# Exit on any error
set -e

echo "Updating and upgrading packages"
sudo apt update && sudo apt upgrade -y

echo "Installing essential packages"
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
  clang \
  gdb \
  cmake \
  jq

# Create necessary directories
echo "Creating necessary directories"
mkdir -p "$HOME"/bin
mkdir -p "$HOME"/.local/bin

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

# Installing Oh My Zsh
echo "Setting up ZSH with Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "Oh My Zsh installed"
else
  echo "Oh My Zsh already installed"
fi

# Install ZSH plugins
echo "Installing ZSH plugins"

# Install zsh-autosuggestions
ZSH_AUTOSUGGESTIONS_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
  echo "zsh-autosuggestions installed"
else
  echo "zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
ZSH_SYNTAX_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
if [ ! -d "$ZSH_SYNTAX_DIR" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_DIR"
  echo "zsh-syntax-highlighting installed"
else
  echo "zsh-syntax-highlighting already installed"
fi

# Copying dotfiles
echo "Copying dotfiles"
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
echo "Setting Zsh as default shell"
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
  echo "Default shell changed to Zsh"
else
  echo "Zsh is already the default shell"
fi

# Final message
echo "Setup complete!"
echo ""
echo -e "${GREEN}Dotfiles have been successfully set up!${NC}"
echo -e "${YELLOW}Note:${NC} Please log out and log back in for all changes to take effect."
echo ""

