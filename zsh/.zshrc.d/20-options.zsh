# Description: Zsh shell options for better UX
# Load order: Early (before interactive use)

# ============================================================================
# Zsh Options for Better UX
# ============================================================================
setopt AUTO_CD               # Auto cd to directories
setopt GLOB_DOTS             # Include hidden files in glob
setopt NO_BEEP               # No annoying beep
setopt PROMPT_SUBST          # Enable prompt substitution
setopt AUTO_PUSHD            # Push directories onto the stack
setopt PUSHD_IGNORE_DUPS     # Don't push duplicate directories
setopt PUSHD_SILENT          # Don't print the directory stack
