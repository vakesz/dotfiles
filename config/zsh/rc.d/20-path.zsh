# PATH and runtime directories

path=("$XDG_BIN_HOME" $path)

if [[ "$OS_TYPE" == "macos" ]]; then
  brew_path=""

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    brew_path="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    brew_path="/usr/local/bin/brew"
  fi

  if [[ -n "$brew_path" ]]; then
    cache_tool_init "$brew_path" "$XDG_CACHE_HOME/zsh/brew-shellenv.zsh" "$brew_path shellenv"
  fi

  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    for package_bin in \
      "$HOMEBREW_PREFIX/opt/curl/bin" \
      "$HOMEBREW_PREFIX/opt/ruby/bin" \
      "$HOMEBREW_PREFIX/opt/make/libexec/gnubin"; do
      [[ -d "$package_bin" ]] && path=("$package_bin" $path)
    done
  fi
elif [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "wsl" ]]; then
  [[ -d "/snap/bin" ]] && path=("/snap/bin" $path)
fi

[[ -d "$GOPATH/bin" ]] && path=("$GOPATH/bin" $path)
[[ -d "$UV_TOOL_BIN_DIR" ]] && path=("$UV_TOOL_BIN_DIR" $path)
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" $path)

export PATH
