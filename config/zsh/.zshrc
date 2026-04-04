for zsh_config in "$ZDOTDIR"/rc.d/*.zsh(N); do
  [[ -r "$zsh_config" ]] && source "$zsh_config"
done

# Local overrides (not tracked in git)
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
