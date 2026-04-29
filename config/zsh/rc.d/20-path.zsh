# PATH and runtime directories

prepend_path() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] && path=("$dir" $path)
  done
}

prepend_path "$XDG_BIN_HOME"

if [[ "$OS_TYPE" == "macos" ]]; then
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$brew_path" ]] || continue
    cached_eval "$XDG_CACHE_HOME/zsh/brew-shellenv.zsh" "$brew_path shellenv" "$brew_path"
    break
  done

  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    prepend_path \
      "$HOMEBREW_PREFIX/opt/curl/bin" \
      "$HOMEBREW_PREFIX/opt/ruby/bin" \
      "$HOMEBREW_PREFIX/opt/make/libexec/gnubin"
  fi
elif [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "wsl" ]]; then
  prepend_path /snap/bin
fi

prepend_path "$GOPATH/bin" "$UV_TOOL_BIN_DIR" "$BUN_INSTALL/bin" "$PNPM_HOME"

export PATH
