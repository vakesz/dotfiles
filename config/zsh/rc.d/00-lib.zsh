# Shared helpers. Test $OSTYPE directly for platform checks.

# .zshenv already made path unique.
typeset -U fpath

_dotfiles_path_prepend() {
  local dir
  for dir in "$@"; do
    [[ -n "$dir" ]] && path=("$dir" "${path[@]}")
  done
  return 0
}

# Succeeds if the directory exists or can be created, and is writable. mkdir
# only forks when the directory is missing. Callers skip caching on failure,
# so a read-only cache or state dir never prints errors at startup.
_dotfiles_writable_dir() {
  [[ -d "$1" ]] || command mkdir -p -- "$1" 2>/dev/null
  [[ -d "$1" && -w "$1" ]]
}

_dotfiles_zcompile() {
  local file="$1"
  [[ -f "$file" && -w "${file:h}" ]] || return 0
  [[ ! -f "${file}.zwc" || "$file" -nt "${file}.zwc" ]] && zcompile -R "$file" 2>/dev/null
  return 0
}

# Package managers like dpkg keep a binary's build mtime on upgrade, so an
# mtime check misses upgrades. ctime is always the install time. zstat is a
# builtin, so no forks; without it the cache falls back to plain -nt.
zmodload -F zsh/stat b:zstat 2>/dev/null && typeset -gi _dotfiles_zstat=1

_dotfiles_cache_source() {
  local cache_file="$1" init_command="$2"; shift 2
  local dep refresh=0 tmp_file
  local -a cache_mtime dep_ctime

  [[ -s "$cache_file" ]] || refresh=1
  (( ! refresh && ${_dotfiles_zstat:-0} )) \
    && zstat -A cache_mtime +mtime -- "$cache_file" 2>/dev/null
  for dep in "$@"; do
    (( refresh )) && break
    # Refresh when a dependency changed since the cache was written, or when it
    # vanished (e.g. the tool was uninstalled) so a stale cache is never sourced.
    [[ ! -e "$dep" ]] && { refresh=1; break; }
    if (( $#cache_mtime )) && zstat -A dep_ctime +ctime -- "$dep" 2>/dev/null; then
      # zstat has whole seconds, so a change in the cache's own second counts.
      (( dep_ctime[1] >= cache_mtime[1] )) && refresh=1
    else
      [[ "$dep" -nt "$cache_file" ]] && refresh=1
    fi
  done

  if (( refresh )); then
    # Can't cache: run the init uncached rather than lose the tool.
    if ! _dotfiles_writable_dir "${cache_file:h}" \
      || ! tmp_file="$(command mktemp "${cache_file:h}/.init.XXXXXX" 2>/dev/null)"; then
      eval "$(eval "$init_command" 2>/dev/null)"
      return 0
    fi
    # init_command comes from hardcoded call sites below (starship init,
    # zoxide init, ...), never from user input, so eval is safe here.
    if eval "$init_command" > "$tmp_file" 2>/dev/null; then
      command mv -f -- "$tmp_file" "$cache_file"
    else
      rm -f -- "$tmp_file"
      return 0
    fi
  fi

  _dotfiles_zcompile "$cache_file"
  source "$cache_file"
}

_dotfiles_cache_tool() {
  local tool="$1" init_command="$2"; shift 2
  (( $+commands[$tool] )) || return 0
  _dotfiles_cache_source "$XDG_CACHE_HOME/zsh/${tool}-init.zsh" "$init_command" "$commands[$tool]" "$@"
}
