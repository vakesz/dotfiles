source "$ZDOTDIR/config.d/env.zsh"
source "$ZDOTDIR/config.d/plugins.zsh"
source "$ZDOTDIR/config.d/completion.zsh"
source "$ZDOTDIR/config.d/aliases.zsh"

# Oh My Posh prompt
_lazy_init oh-my-posh "oh-my-posh init zsh --config $XDG_CONFIG_HOME/oh-my-posh/zen.toml"

if ! have oh-my-posh; then
  PROMPT='%F{#7dcfff}%~%f %F{#737aa2}❯%f '
fi

# Local overrides (not tracked in git)
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"