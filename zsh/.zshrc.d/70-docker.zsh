# Description: Docker aliases and shortcuts
# Dependencies: docker

# Only load if Docker is installed
if ! have docker; then
    return
fi

# ============================================================================
# Docker Aliases
# ============================================================================
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
