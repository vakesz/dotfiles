# Fall back to this file's directory if ZDOTDIR is unset or empty (zsh -f, or an
# empty inherited value), so the loop below never globs /rc.d/*.zsh.
: "${ZDOTDIR:=${${(%):-%N}:A:h}}"

# -. skips dangling links: stow leaves one behind when a file is deleted from
# the repo, until bootstrap restows.
for zsh_config in "$ZDOTDIR"/rc.d/*.zsh(N-.); do
  source "$zsh_config"
done
unset zsh_config

# Untracked machine-local overrides
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# Normalize the startup status: the guards above return 1 when an optional
# file is absent, which a bare `exit` would otherwise propagate.
true
