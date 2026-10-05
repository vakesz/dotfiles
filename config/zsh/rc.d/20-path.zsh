# PATH for interactive shells (~/.zshenv sets the base PATH for every shell)

_dotfiles_path_prepend "$XDG_BIN_HOME"

if [[ $OS_TYPE == macos ]]; then
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$brew_path" ]] || continue
    _dotfiles_cache_source "$XDG_CACHE_HOME/zsh/brew-shellenv.zsh" "$brew_path shellenv" "$brew_path"
    break
  done
  unset brew_path

  if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
    # Keg-only formulae and ccache's compiler wrappers. Left out on purpose:
    # llvm/bin would shadow Apple clang, and coreutils' gnubin breaks GMP builds.
    _dotfiles_path_prepend \
      "$HOMEBREW_PREFIX/opt/curl/bin" \
      "$HOMEBREW_PREFIX/opt/ruby/bin" \
      "$HOMEBREW_PREFIX/opt/make/libexec/gnubin" \
      "$HOMEBREW_PREFIX/opt/flex/bin" \
      "$HOMEBREW_PREFIX/opt/bison/bin" \
      "$HOMEBREW_PREFIX/opt/rustup/bin" \
      "$HOMEBREW_PREFIX/opt/ccache/libexec"
  fi
elif [[ $OS_TYPE == linux ]]; then
  _dotfiles_path_prepend /snap/bin
fi

_dotfiles_path_prepend "$GOPATH/bin" "$UV_TOOL_BIN_DIR" "$GEM_HOME/bin" "$CARGO_HOME/bin"

export PATH
