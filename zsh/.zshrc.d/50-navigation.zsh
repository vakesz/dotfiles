# Description: Directory navigation shortcuts and tools
# Dependencies: zoxide (optional, smart directory jumping)

# ============================================================================
# Directory Navigation
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Zoxide - smart directory jumping (replaces cd)
if have zoxide; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi
