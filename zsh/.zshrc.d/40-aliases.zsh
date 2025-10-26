# Description: Modern CLI tool aliases (lsd, bat, etc.)
# Dependencies: lsd, bat (optional, fallback to standard tools)

# ============================================================================
# Modern CLI Tools Aliases
# ============================================================================

# Use lsd instead of ls (colorful, icon-rich listing)
if have lsd; then
    alias ls='lsd'
    alias ll='lsd -lah'
    alias la='lsd -A'
    alias lt='lsd --tree --depth 2'
    alias l='lsd -lh'
else
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -lh'
fi

# Use bat instead of cat (syntax highlighting)
if have bat; then
    alias cat='bat --paging=never --style=plain'
    alias ccat='bat --paging=never'  # cat with colors
    alias less='bat'
fi
