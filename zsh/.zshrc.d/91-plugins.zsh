# Description: Zsh plugins (autosuggestions, syntax highlighting, completions)
# Dependencies: Homebrew packages (zsh-autosuggestions, zsh-fast-syntax-highlighting, zsh-completions)
# Load order: After completions, before prompt

if [[ -z "$HOMEBREW_PREFIX" ]]; then
    return
fi

# ============================================================================
# Zsh Plugins (Cross-Platform)
# ============================================================================

# Autosuggestions (Fish-like command suggestions from history)
if [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax highlighting (load after autosuggestions)
if [[ -f "$HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi

# Additional completions
if [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]]; then
    FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
fi
