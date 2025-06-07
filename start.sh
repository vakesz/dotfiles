#!/bin/bash
set -Eeuo pipefail
trap 'error "Error on line $LINENO"; exit 1' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
Setup dotfiles across different operating systems.

Options:
  --help      Show this help message and exit

Supported OS:
  - Linux (Ubuntu/Debian including WSL)
  - macOS
  - Windows (via Git Bash/MSYS)
EOF
}

detect_os() {
    case "$(uname -s)" in
        Linux*)
            OS="linux"
            # Log if it's WSL for informational purposes
            if grep -q microsoft /proc/version 2>/dev/null; then
                log "WSL detected - using Linux setup"
            fi
            ;;
        Darwin*)
            OS="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS="windows"
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    
    log "Detected OS: $OS"
}

run_setup() {
    local script_path="setup_scripts/${OS}.sh"
    
    if [ ! -f "$script_path" ]; then
        error "Setup script not found: $script_path"
        exit 1
    fi
    
    log "Running setup script: $script_path"
    chmod +x "$script_path"
    bash "$script_path" "$@"
}

# Handle flags
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Main execution
log "Starting dotfiles setup"

detect_os
run_setup "$@"

log "Setup completed successfully!"