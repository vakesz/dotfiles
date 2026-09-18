# Shell plugins. Highlighting loads last so it wraps every widget defined above.

# Read at load time, so both must be set before the plugin is sourced. Without
# MANUAL_REBIND the plugin re-binds every widget on each prompt.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
