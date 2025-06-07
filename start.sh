#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
Setup dotfiles on Ubuntu/Debian.

Options:
  --help      Show this help message and exit

Preconditions:
  Must have sudo privileges
  Do not run this script as root
EOF
}

# Handle flags
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

detect_os() {
    if [ ! -f /etc/os-release ]; then
        error "Cannot detect OS distribution"
        exit 1
    fi
    
    # shellcheck disable=SC1091
    if ! . /etc/os-release; then
        error "Failed to source /etc/os-release"
        exit 1
    fi
    
    OS=$ID
    
    case $OS in
        ubuntu|debian) log "Detected $OS $VERSION_ID" ;;
        *) error "Unsupported OS: $OS. This script supports Ubuntu and Debian only."; exit 1 ;;
    esac
}

backup_dotfiles() {
    log "Backing up existing dotfiles"
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    for file in .gitconfig .zshrc; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_DIR/"
        fi
    done
}

install_packages() {
    log "Installing essential packages"
    sudo apt update && sudo apt upgrade -y

    # Define packages as an array
    PACKAGES=(
        git neovim python3 python3-pip python3-venv build-essential mc zsh curl wget htop tree
        software-properties-common apt-transport-https ca-certificates gnupg lsb-release
        clang gdb cmake jq unzip zip ripgrep fd-find bat fzf
    )

    # Install packages
    sudo apt install -y "${PACKAGES[@]}"
}

install_tools() {
    # Lazygit
    if ! command -v lazygit &> /dev/null; then
        log "Installing lazygit"
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi

    # Rust and cargo tools
    if ! command -v rustc &> /dev/null; then
        log "Installing Rust and cargo tools"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
        cargo install bottom hyperfine
    fi

    # Delta
    if ! command -v delta &> /dev/null; then
        log "Installing Delta"
        DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r .tag_name | tr -d 'v')
        wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
        sudo dpkg -i git-delta_"${DELTA_VERSION}"_amd64.deb
        rm git-delta_"${DELTA_VERSION}"_amd64.deb
    fi
}

install_docker() {
    if command -v docker &> /dev/null; then
        return
    fi
    
    log "Installing Docker"
    curl -fsSL https://download.docker.com/linux/"$OS"/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker "$USER"
}

install_nodejs() {
    if command -v node &> /dev/null; then
        return
    fi
    
    log "Installing Node.js"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
}

install_node_packages() {
    log "Installing Tailwind CSS and ESLint globally"

    # Ensure Node.js is installed
    if ! command -v node &> /dev/null; then
        log "Node.js is not installed. Installing Node.js first."
        install_nodejs
    fi

    # Install Tailwind CSS globally
    log "Installing Tailwind CSS globally"
    sudo npm install -g tailwindcss postcss autoprefixer

    # Install ESLint globally
    log "Installing ESLint globally"
    sudo npm install -g eslint

    log "Global installation of Tailwind CSS and ESLint completed"
}

install_font() {
    log "Installing JetBrains Mono Nerd Font"
    FONT_DIR="$HOME/.local/share/fonts"
    
    if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
        mkdir -p "$FONT_DIR"
        cd "$FONT_DIR"
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
        unzip -q JetBrainsMono.zip -d JetBrainsMono/
        rm JetBrainsMono.zip
        fc-cache -fv
        cd - > /dev/null
    fi
}

setup_zsh() {
    log "Setting up ZSH with Oh My Zsh"
    
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    
    # Install plugins
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    for plugin in zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-completions; do
        PLUGIN_DIR="$ZSH_CUSTOM/plugins/$plugin"
        if [ ! -d "$PLUGIN_DIR" ]; then
            case $plugin in
                zsh-autosuggestions) 
                    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR" ;;
                zsh-syntax-highlighting) 
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR" ;;
                fast-syntax-highlighting) 
                    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_DIR" ;;
                zsh-completions) 
                    git clone https://github.com/zsh-users/zsh-completions "$PLUGIN_DIR" ;;
            esac
        fi
    done
}

copy_dotfiles() {
    log "Copying dotfiles"
    cp .gitconfig ~/.gitconfig
    cp .zshrc ~/.zshrc
    
    # Copy bin scripts
    mkdir -p "$HOME/bin"
    if [ -d "bin" ]; then
        cp bin/* "$HOME/bin/"
        chmod +x "$HOME/bin/"*
    fi
}

finalize_setup() {
    # Set Zsh as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        log "Default shell changed to Zsh"
    fi
    
    # WSL2 Git configuration and locale setup
    if grep -q microsoft /proc/version 2>/dev/null; then
        log "Configuring Git and locale for WSL2"
        git config --global --add safe.directory '*'
        
        # Ensure locale is properly configured for WSL
        if [ ! -f /etc/locale.gen ] || ! grep -q "^en_US.UTF-8" /etc/locale.gen; then
            echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
        fi
        sudo locale-gen en_US.UTF-8 2>/dev/null
        
        # Set system-wide locale
        echo 'LANG=en_US.UTF-8' | sudo tee /etc/default/locale > /dev/null
        echo 'LC_ALL=en_US.UTF-8' | sudo tee -a /etc/default/locale > /dev/null
        
        log "WSL locale configuration completed"
    fi
}

toolkit_post_install_checks() {
    log "Running post-install checks"
    for cmd in git zsh docker node npm; do
        if ! command -v $cmd &> /dev/null; then
            warn "$cmd not found in PATH"
        else
            log "$cmd is available at $(which $cmd)"
        fi
    done
    log "Post-install cleanup completed"
    echo -e "${YELLOW}Please log out and log back in to apply shell changes.${NC}"
}

# Main execution
log "Starting dotfiles setup"

[ "$EUID" -eq 0 ] && { error "Please do not run this script as root"; exit 1; }

detect_os
backup_dotfiles
install_packages
install_tools
install_docker
install_nodejs
install_node_packages
install_font
setup_zsh
copy_dotfiles
finalize_setup
toolkit_post_install_checks

log "Setup complete!"
echo -e "${GREEN}Dotfiles have been successfully set up!${NC}"
echo -e "${YELLOW}Note: Please log out and log back in for all changes to take effect.${NC}"

