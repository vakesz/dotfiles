# PATH for interactive shells ($ZDOTDIR/.zshenv sets the base PATH for every shell)

_dotfiles_path_prepend "$XDG_BIN_HOME"

# Homebrew shellenv is cached (see 00-lib.zsh). macOS uses the two standard
# prefixes; Linux supports Linuxbrew in its standard locations. Never probe
# /home on macOS: it's an automount, and the lookup stalls startup.
case "$OSTYPE" in
  darwin*) brew_paths=(/opt/homebrew/bin/brew /usr/local/bin/brew) ;;
  linux*)  brew_paths=(/home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew") ;;
  *)       brew_paths=() ;;
esac
for brew_path in "${brew_paths[@]}"; do
  [[ -x "$brew_path" ]] || continue
  _dotfiles_cache_source "$XDG_CACHE_HOME/zsh/brew-shellenv.zsh" "$brew_path shellenv" "$brew_path"
  break
done
unset brew_path brew_paths

if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  # Keg-only formulae and ccache's compiler wrappers, when installed. Left out
  # on purpose: llvm/bin would shadow Apple clang, and coreutils' gnubin breaks
  # GMP builds.
  for keg_dir in \
    "$HOMEBREW_PREFIX/opt/curl/bin" \
    "$HOMEBREW_PREFIX/opt/ruby/bin" \
    "$HOMEBREW_PREFIX/opt/make/libexec/gnubin" \
    "$HOMEBREW_PREFIX/opt/flex/bin" \
    "$HOMEBREW_PREFIX/opt/bison/bin" \
    "$HOMEBREW_PREFIX/opt/ccache/libexec"; do
    [[ -d "$keg_dir" ]] && _dotfiles_path_prepend "$keg_dir"
  done
  unset keg_dir
fi

[[ -d /snap/bin ]] && _dotfiles_path_prepend /snap/bin

_dotfiles_path_prepend \
  "${COMPOSER_HOME:-$XDG_CONFIG_HOME/composer}/vendor/bin" \
  "$GOPATH/bin" "$UV_TOOL_BIN_DIR" "$GEM_HOME/bin" "$CARGO_HOME/bin"

# Homebrew's rustup wrappers must win over the proxies rustup installs in
# $CARGO_HOME/bin, so brew upgrades never leave stale cargo and rustc shims.
# Keep this last: the cached shellenv above re-fronted Homebrew's bin, which
# pushed the wrappers .zshenv placed first back behind it.
if [[ -n ${HOMEBREW_PREFIX:-} && -d "$HOMEBREW_PREFIX/opt/rustup/bin" ]]; then
  _dotfiles_path_prepend "$HOMEBREW_PREFIX/opt/rustup/bin"
fi
