source "$ZDOTDIR/config.d/env.zsh"
source "$ZDOTDIR/config.d/plugins.zsh"
source "$ZDOTDIR/config.d/completion.zsh"
source "$ZDOTDIR/config.d/aliases.zsh"

# Local overrides (not tracked in git)
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"