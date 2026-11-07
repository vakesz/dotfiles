#!/bin/zsh -f
# Copy the variables ~/.zshenv exports into the launchd user session, so apps
# opened from Finder, the Dock or login items get the same XDG and tool
# locations as the shell instead of falling back to dot-directories in $HOME.
# The launchd-env LaunchAgent that macos.sh installs runs this at login.
# Apps that are already running only pick up the change after a restart.

emulate -L zsh

# PATH stays out: launchd's PATH is shared with system services, and GUI apps
# that need the shell PATH (editors, terminals) resolve it themselves.
local -a skip=(PATH PWD OLDPWD SHLVL _ HOME USER LOGNAME SHELL TMPDIR)
local -A before
local name

for name in ${(k)parameters[(R)*export*]}; do
  before[$name]=${(P)name}
done

source "$HOME/.zshenv" || exit 1

for name in ${(ko)parameters[(R)*export*]}; do
  (( ${skip[(Ie)$name]} )) && continue
  # Skip what launchd passed in unchanged, which includes values from an earlier run.
  [[ ${+before[$name]} == 1 && ${before[$name]} == ${(P)name} ]] && continue
  launchctl setenv "$name" "${(P)name}"
done
