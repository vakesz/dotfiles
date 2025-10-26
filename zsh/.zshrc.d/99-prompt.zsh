# Description: Starship prompt configuration
# Dependencies: starship
# Load order: Last (prompt should be configured after everything else)

if ! have starship; then
    return
fi

# ============================================================================
# Starship Prompt
# ============================================================================
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"
