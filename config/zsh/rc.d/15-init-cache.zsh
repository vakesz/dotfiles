# Cached shell initialization

compile_zsh_file_if_stale() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  [[ ! -f "${file}.zwc" || "$file" -nt "${file}.zwc" ]] && zcompile -R "$file" 2>/dev/null
  return 0
}

source_cached_init() {
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

  compile_zsh_file_if_stale "$cache_file"
  source "$cache_file"
}

load_cached_tool_init() {
  local tool="$1" init_command="$2"; shift 2
  (( $+commands[$tool] )) || return 0
  source_cached_init "$XDG_CACHE_HOME/zsh/${tool}-init.zsh" "$init_command" "$commands[$tool]" "$@"
}
