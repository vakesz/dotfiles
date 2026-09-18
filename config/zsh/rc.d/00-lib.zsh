# Shared helpers and platform detection

typeset -U path fpath

typeset -g OS_TYPE="unknown"
case "$OSTYPE" in
  darwin*) OS_TYPE="macos" ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS_TYPE="wsl"
    else
      OS_TYPE="linux"
    fi
    ;;
esac

_dotfiles_path_prepend() {
  local dir
  for dir in "$@"; do
    [[ -n "$dir" ]] && path=("$dir" $path)
  done
  return 0
}

_dotfiles_zcompile() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  [[ ! -f "${file}.zwc" || "$file" -nt "${file}.zwc" ]] && zcompile -R "$file" 2>/dev/null
  return 0
}

_dotfiles_cache_source() {
  local cache_file="$1" init_command="$2"; shift 2
  local dep refresh=0 tmp_file

  [[ -s "$cache_file" ]] || refresh=1
  for dep in "$@"; do
    [[ -e "$dep" && "$dep" -nt "$cache_file" ]] && { refresh=1; break; }
  done

  if (( refresh )); then
    mkdir -p "${cache_file:h}"
    tmp_file="${cache_file}.$$"
    if eval "$init_command" > "$tmp_file" 2>/dev/null; then
      mv "$tmp_file" "$cache_file"
    else
      rm -f "$tmp_file"
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
