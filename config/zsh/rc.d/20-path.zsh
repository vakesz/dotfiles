# PATH additions for interactive shells only ($ZDOTDIR/.zshenv sets the PATH
# every shell gets).

# Keg-only formulae and ccache's compiler wrappers, when installed. They change
# what cc, make, curl and ruby resolve to, so builds started from IDEs and git
# hooks don't get them. They go just ahead of Homebrew's bin, so $XDG_BIN_HOME
# and the tool bins still win. Left out on purpose: llvm/bin would shadow
# Apple clang, and coreutils' gnubin breaks GMP builds.
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  _dotfiles_kegs=(
    "$HOMEBREW_PREFIX/opt/ccache/libexec"
    "$HOMEBREW_PREFIX/opt/curl/bin"
    "$HOMEBREW_PREFIX/opt/ruby/bin"
    "$HOMEBREW_PREFIX/opt/make/libexec/gnubin"
    "$HOMEBREW_PREFIX/opt/flex/bin"
    "$HOMEBREW_PREFIX/opt/bison/bin"
  )
  # Index of Homebrew's bin, or one past the end if it isn't on PATH.
  _dotfiles_brew_index=${path[(ie)$HOMEBREW_PREFIX/bin]}
  path[_dotfiles_brew_index,_dotfiles_brew_index-1]=(${^_dotfiles_kegs}(N-/))
  unset _dotfiles_kegs _dotfiles_brew_index
fi
