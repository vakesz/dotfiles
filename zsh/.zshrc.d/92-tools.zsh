# Description: Tool configurations (fzf, ripgrep, etc.)
# Dependencies: fzf, bat, fd (optional)
# Load order: After plugins, before prompt

# ============================================================================
# fzf Configuration (Fuzzy Finder)
# ============================================================================
if have fzf; then
    # Setup fzf key bindings and completion
    eval "$(fzf --zsh)"

    # Use bat for preview if available
    if have bat; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
    fi

    # Better color scheme for fzf
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"

    # Use fd instead of find if available
    if have fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi
