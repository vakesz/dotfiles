for zsh_config in "$ZDOTDIR"/rc.d/*.zsh(N); do
  [[ -r "$zsh_config" ]] && source "$zsh_config"
done

# Local overrides stay untracked and can live alongside the stowed config.
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
