# Fall back to this file's directory if ZDOTDIR is unset or empty (zsh -f, or an
# empty inherited value), so the loop below never globs /rc.d/*.zsh.
: "${ZDOTDIR:=${${(%):-%N}:A:h}}"

for zsh_config in "$ZDOTDIR"/rc.d/*.zsh(N); do
  [[ -r "$zsh_config" ]] && source "$zsh_config"
done

# Untracked machine-local overrides
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
