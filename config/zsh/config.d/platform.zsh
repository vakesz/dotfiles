# Platform Detection (sets OS_TYPE: macos, linux, wsl, unknown)

case "$OSTYPE" in
  darwin*)
    export OS_TYPE="macos"
    ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      export OS_TYPE="wsl"
    else
      export OS_TYPE="linux"
    fi
    ;;
  *)
    export OS_TYPE="unknown"
    ;;
esac

have() {
  command -v "$1" >/dev/null 2>&1
}

alias_if_exists() {
  have "$2" && alias "$1=$3"
}

# Cache a tool's init output, regenerating when the binary changes.
# Usage: _cache_init <binary> <cache_file> <command>
_cache_init() {
  local bin_path cache_file cmd
  bin_path=$(command -v "$1") || return 1
  cache_file="$2"
  cmd="$3"
  if [[ ! -f "$cache_file" || "$bin_path" -nt "$cache_file" ]]; then
    mkdir -p "${cache_file:h}"
    eval "$cmd" > "$cache_file" 2>/dev/null
  fi
  source "$cache_file"
}
