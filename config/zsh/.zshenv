# Nested shells inherit ZDOTDIR, so zsh reads this file instead of ~/.zshenv.
# Load it so they get the same environment as the parent.
[[ -r "$HOME/.zshenv" ]] && source "$HOME/.zshenv"
