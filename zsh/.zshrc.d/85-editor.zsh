# Description: Editor configuration (Neovim)
# Dependencies: nvim

if ! have nvim; then
    return
fi

# ============================================================================
# Editor Configuration
# ============================================================================
alias vi='nvim'
alias vim='nvim'
export EDITOR='nvim'
export VISUAL='nvim'
export MANPAGER='nvim +Man!'  # Use nvim as man pager
