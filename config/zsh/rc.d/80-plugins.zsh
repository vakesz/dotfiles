# Shell plugins (must load after completion and keybindings)
#
# Order matters: zsh-autosuggestions first, then zsh-syntax-highlighting LAST so
# it wraps every widget defined above (completion, keybindings, suggestions).

# Both must be set before the plugin is sourced; it reads them at load time.
#
# Without MANUAL_REBIND the plugin re-binds every widget on each prompt, which
# is the single largest cost it adds. Setting it means a plugin sourced *after*
# this one would not be wrapped — zsh-syntax-highlighting below wraps
# autosuggestions rather than the reverse, so the order stays correct.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Stop searching history for suggestions on very long lines, where the scan
# costs more than the suggestion is worth.
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
