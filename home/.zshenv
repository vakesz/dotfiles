# zsh only reads ~/.zshenv until ZDOTDIR is set. The environment lives in
# $ZDOTDIR/.zshenv, which nested shells (inheriting ZDOTDIR) read directly.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
# Guarded so a preset XDG_CONFIG_HOME without our config stays quiet.
[[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
