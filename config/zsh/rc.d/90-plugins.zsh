# Shell plugins. Syntax highlighting loads last so it wraps every widget.

# Both are read when the plugin loads. MANUAL_REBIND stops it from rebinding
# every widget at each prompt.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100
# Skip highlighting very long buffers so big pastes don't lag.
ZSH_HIGHLIGHT_MAXLENGTH=512

# Homebrew first, then distro packages: /usr/share/<name> on Debian, Ubuntu
# and Fedora, /usr/share/zsh/plugins/<name> on Arch. Sets REPLY rather than
# sourcing, because plugins sourced inside a function would get local scope.
_dotfiles_find_plugin() {
  local name="$1"
  for REPLY in \
    ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/$name/$name.zsh} \
    "/usr/share/$name/$name.zsh" \
    "/usr/share/zsh/plugins/$name/$name.zsh"; do
    [[ -r "$REPLY" ]] && return 0
  done
  return 1
}

_dotfiles_find_plugin zsh-autosuggestions && source "$REPLY"
_dotfiles_find_plugin zsh-syntax-highlighting && source "$REPLY"
unfunction _dotfiles_find_plugin
unset REPLY
