# Description: Git aliases and configuration
# Dependencies: git, delta (optional)

# ============================================================================
# Git Aliases
# ============================================================================
alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gf='git fetch'

# ============================================================================
# Git Delta Configuration (Better git diff)
# ============================================================================
if have delta; then
    export GIT_PAGER='delta'
fi
