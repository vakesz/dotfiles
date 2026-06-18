# Shell plugins (must load after completion and keybindings)
#
# Order matters: zsh-autosuggestions first, then zsh-syntax-highlighting LAST so
# it wraps every widget defined above (completion, keybindings, suggestions).

[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
