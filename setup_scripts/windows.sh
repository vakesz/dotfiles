#!/bin/bash
set -Eeuo pipefail
trap 'error "Error on line $LINENO"; exit 1' ERR

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
Setup dotfiles on Windows

Options:
  --help      Show this help message and exit
EOF
}

# Handle flags
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

install_chocolatey() {
    if ! command -v choco &> /dev/null; then
        log "Installing Chocolatey package manager"
        powershell.exe -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" || warn "Failed to install Chocolatey"
    else
        log "Chocolatey is already installed"
    fi
}

install_packages() {
    log "Installing essential packages via Chocolatey"
    
    # Define packages as an array
    PACKAGES=(
        git neovim
        jetbrainsmono-nerd-font
        fzf ripgrep fd bat
        lazygit
        gimp
        starship
        firefox
        vlc
        microsoft-windows-terminal
        discord
        notepadplusplus
        spotify
        teamspeak
        wsl2
        unigetui
    )

    # Install packages via Chocolatey
    if command -v choco &> /dev/null; then
        choco install -y "${PACKAGES[@]}" || warn "Some packages failed to install via Chocolatey"
    else
        warn "Chocolatey not available, please install packages manually"
    fi
}

setup_git_bash() {
    log "Setting up Git Bash configuration"
    
    # Check if we're in Git Bash
    if [[ "$TERM_PROGRAM" == "mintty" ]] || [[ "$MSYSTEM" =~ ^MINGW ]]; then
        log "Git Bash detected"
        
        # Set up aliases for Windows
        cat >> "$HOME/.bashrc" << 'EOF'

# Windows-specific aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Modern alternatives
if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi
EOF
    fi
}

setup_powershell_profile() {
    log "Setting up PowerShell profile"
    
    # Create PowerShell profile directory if it doesn't exist
    POWERSHELL_PROFILE_DIR="$HOME/Documents/WindowsPowerShell"
    mkdir -p "$POWERSHELL_PROFILE_DIR"
    
    # Create basic PowerShell profile
    cat > "$POWERSHELL_PROFILE_DIR/Microsoft.PowerShell_profile.ps1" << 'EOF'
# PowerShell Profile

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Set JetBrains Mono font for Windows Terminal
if ($env:WT_SESSION) {
    # Windows Terminal detected - font should be set in settings.json
    Write-Host "Windows Terminal detected. Configure JetBrains Mono Nerd Font in Windows Terminal settings." -ForegroundColor Yellow
}

# Initialize Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# Aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name grep -Value Select-String
EOF
}

finalize_setup() {
    log "Finalizing Windows setup"
    
    # Windows-specific Git configuration
    git config --global core.autocrlf true
    git config --global core.filemode false
    git config --global --add safe.directory '*'
    
    log "Windows Git configuration applied"
}

toolkit_post_install_checks() {
    log "Running post-install checks"
    
    # Check essential commands
    COMMANDS=("git" "starship" "nvim")
    
    for cmd in "${COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            warn "$cmd not found in PATH"
        else
            log "$cmd is available at $(where "$cmd" 2>/dev/null || echo "unknown location")"
        fi
    done
    
    log "Post-install cleanup completed"
    echo -e "${YELLOW}Please restart your terminal to apply all changes.${NC}"
}

# Main execution
log "Starting Windows dotfiles setup"

install_chocolatey
install_packages
setup_git_bash
setup_powershell_profile
finalize_setup
toolkit_post_install_checks

log "Windows setup complete!"
echo -e "${GREEN}Dotfiles have been successfully set up for Windows!${NC}"
echo -e "${YELLOW}Note: Please restart your terminal for all changes to take effect.${NC}"