# PATH and runtime directories

prepend_path() {
  local dir
  for dir in "$@"; do
    [[ -n "$dir" ]] && path=("$dir" $path)
  done
}

prepend_path "$XDG_BIN_HOME"

if [[ $OS_TYPE == macos ]]; then
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$brew_path" ]] || continue
    source_cached_init "$XDG_CACHE_HOME/zsh/brew-shellenv.zsh" "$brew_path shellenv" "$brew_path"
    break
  done
  unset brew_path

  if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
    # Homebrew LLVM stays keg-only: putting llvm/bin on PATH would shadow
    # Apple clang. macos.sh symlinks dlltool into ~/.local/bin instead.
    prepend_path \
      "$HOMEBREW_PREFIX/opt/curl/bin" \
      "$HOMEBREW_PREFIX/opt/sqlite/bin" \
      "$HOMEBREW_PREFIX/opt/ruby/bin" \
      "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" \
      "$HOMEBREW_PREFIX/opt/make/libexec/gnubin" \
      "$HOMEBREW_PREFIX/opt/flex/bin" \
      "$HOMEBREW_PREFIX/opt/bison/bin"
  fi
elif [[ $OS_TYPE == linux || $OS_TYPE == wsl ]]; then
  prepend_path /snap/bin
fi

prepend_path "$GOPATH/bin" "$UV_TOOL_BIN_DIR" "$GEM_HOME/bin"

export PATH
