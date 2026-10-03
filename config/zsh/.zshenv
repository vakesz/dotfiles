# Nested Zsh instances inherit ZDOTDIR and therefore read this file instead of
# ~/.zshenv. Keep the non-interactive environment consistent with the parent.
[[ -r "$HOME/.zshenv" ]] && source "$HOME/.zshenv"
