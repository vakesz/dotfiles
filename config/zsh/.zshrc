source "$ZDOTDIR/config.d/env.zsh"
source "$ZDOTDIR/config.d/plugins.zsh"
source "$ZDOTDIR/config.d/completion.zsh"
source "$ZDOTDIR/config.d/aliases.zsh"

# Oh My Posh prompt - load directly since it's always needed for the prompt
eval "$(oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/zen.toml")"

# Local overrides (not tracked in git)
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"